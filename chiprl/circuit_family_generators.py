"""Frozen 32-bit structural boundary-mask generators for three non-adder circuits.

A mask has 31 bits: bit i inserts a boundary between datapath bits i and i+1.
The complete 2**31 action space is supported for each circuit family.
"""
from __future__ import annotations

from pathlib import Path

WIDTH = 32
BITS = WIDTH - 1
MAX_MASK = (1 << BITS) - 1
FAMILIES = ('cmp32', 'popcount32', 'priority32')
OUTPUT_BITS = {'cmp32': 1, 'popcount32': 6, 'priority32': 6}


def blocks_from_mask(mask: int) -> tuple[int, ...]:
    if not (0 <= mask <= MAX_MASK):
        raise ValueError(f'expected {BITS}-bit mask, got {mask}')
    out, width = [], 1
    for i in range(BITS):
        if mask & (1 << i):
            out.append(width)
            width = 1
        else:
            width += 1
    out.append(width)
    assert sum(out) == WIDTH
    return tuple(out)


def mask_from_blocks(blocks) -> int:
    if not blocks or any(b <= 0 for b in blocks) or sum(blocks) != WIDTH:
        raise ValueError('blocks must be positive and sum to 32')
    mask, pos = 0, 0
    for b in blocks[:-1]:
        pos += b
        mask |= (1 << (pos - 1))
    return mask


def spans(mask: int):
    lo = 0
    for w in blocks_from_mask(mask):
        hi = lo + w - 1
        yield lo, hi
        lo = hi + 1


def _header(family: str) -> list[str]:
    ybits = OUTPUT_BITS[family]
    return [
        f'module {family} (',
        '    input wire clk,',
        '    input wire rst_n,',
        '    input wire valid_i,',
        '    input wire [31:0] a_i,',
        '    input wire [31:0] b_i,',
        '    output reg valid_o,',
        f'    output reg [{ybits-1}:0] y_o',
        ');',
        '',
    ]


def render(family: str, mask: int) -> str:
    if family not in FAMILIES:
        raise ValueError(f'unknown circuit family: {family}')
    lines = _header(family)
    bounds = list(spans(mask))

    if family == 'cmp32':
        # Compare each chunk, then combine from least-significant to
        # most-significant. Higher chunks take precedence on inequality.
        for i, (lo, hi) in enumerate(bounds):
            a = f'a_i[{hi}:{lo}]' if hi > lo else f'a_i[{lo}]'
            b = f'b_i[{hi}:{lo}]' if hi > lo else f'b_i[{lo}]'
            lines += [
                f'wire lt_{i} = ({a} < {b});',
                f'wire eq_{i} = ({a} == {b});',
            ]
        lines += ['', 'wire cmp_0 = lt_0;']
        for i in range(1, len(bounds)):
            lines.append(
                f'wire cmp_{i} = lt_{i} | (eq_{i} & cmp_{i-1});'
            )
        result = f'cmp_{len(bounds)-1}'
    elif family == 'popcount32':
        # Explicit per-segment reduction, then a chain of segment sums.
        # Overflow cannot occur: 0 <= count <= 32 < 2**6.
        for i, (lo, hi) in enumerate(bounds):
            expr = "6'd0" + ''.join(
                f" + {{5'd0, a_i[{bit}]}}" for bit in range(lo, hi + 1)
            )
            lines.append(f'wire [5:0] pc_{i} = {expr};')
        lines += ['', 'wire [5:0] total_0 = pc_0;']
        for i in range(1, len(bounds)):
            lines.append(
                f'wire [5:0] total_{i} = total_{i-1} + pc_{i};'
            )
        result = f'total_{len(bounds)-1}'
    else:
        # Result {found,index} of highest asserted input bit; zero on no hit.
        for i, (lo, hi) in enumerate(bounds):
            vec = f'a_i[{hi}:{lo}]' if hi > lo else f'a_i[{lo}]'
            terms = [
                f"a_i[{j}] ? 5'd{j}" for j in range(hi, lo - 1, -1)
            ]
            expr = ' : '.join(terms) + " : 5'd0"
            lines += [
                f'wire hit_{i} = |{vec};',
                f'wire [4:0] idx_{i} = {expr};',
            ]
        lines += [
            '',
            "wire [5:0] chosen_0 = hit_0 ? {1'b1, idx_0} : 6'd0;",
        ]
        for i in range(1, len(bounds)):
            lines.append(
                f"wire [5:0] chosen_{i} = hit_{i} ? "
                f"{{1'b1, idx_{i}}} : chosen_{i-1};"
            )
        result = f'chosen_{len(bounds)-1}'

    lines += [
        '',
        'always @(posedge clk) begin',
        '    if (!rst_n) begin',
        "        valid_o <= 1'b0;",
        f"        y_o <= {OUTPUT_BITS[family]}'d0;",
        '    end else begin',
        '        valid_o <= valid_i;',
        '        if (valid_i)',
        f'            y_o <= {result};',
        '    end',
        'end',
        'endmodule',
        '',
    ]
    return '\n'.join(lines)


def write_candidate(family: str, mask: int, path: str | Path) -> Path:
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(render(family, mask))
    return path


def python_oracle(family: str, a: int, b: int) -> int:
    a &= 0xffffffff
    b &= 0xffffffff
    if family == 'cmp32':
        return int(a < b)
    if family == 'popcount32':
        return a.bit_count()
    if family == 'priority32':
        return ((1 << 5) | (a.bit_length() - 1)) if a else 0
    raise ValueError(family)
