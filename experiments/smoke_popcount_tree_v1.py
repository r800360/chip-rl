"""Zero-EDA exhaustive local arithmetic test and generator sanity checks."""
from __future__ import annotations

import random
from chiprl.popcount_tree_generator import (
    BITS, MAX_MASK, PILOT_MASKS, python_oracle, render,
)


def cla(x: int, y: int, w: int) -> int:
    p = [((x >> i) & 1) ^ ((y >> i) & 1) for i in range(w)]
    g = [((x >> i) & 1) & ((y >> i) & 1) for i in range(w)]
    z = p[0]
    for bit in range(1, w + 1):
        carry = 0
        for generated in range(bit):
            term = g[generated]
            for propagated in range(generated + 1, bit):
                term &= p[propagated]
            carry |= term
        if bit < w:
            z |= (p[bit] ^ carry) << bit
        else:
            z |= carry << w
    return z


def model(mask: int, operand: int) -> int:
    mask = int(mask)
    nodes = [(operand >> i) & 1 for i in range(32)]
    index = 0
    for level in range(5):
        following = []
        for i in range(0, len(nodes), 2):
            x, y = nodes[i], nodes[i + 1]
            z = cla(x, y, level + 1) if mask & (1 << index) else x + y
            assert z <= 2**(level+1)
            following.append(z)
            index += 1
        nodes = following
    assert len(nodes) == 1 and index == 31
    return nodes[0]


def run():
    assert len(PILOT_MASKS) == 8 and len(set(PILOT_MASKS)) == 8
    for w in range(1, 6):
        for x in range(1 << w):
            for y in range(1 << w):
                assert cla(x, y, w) == x + y, (x, y, w)
    print('PASS: exhaustive carry-lookahead arithmetic for widths 1..5')
    for mask in PILOT_MASKS:
        rtl = render(mask)
        assert rtl.count('// node ') == BITS
        assert rtl.count('// architecture_mask') == 1
        assert rtl.endswith('endmodule\n')
    assert len({render(m) for m in PILOT_MASKS}) == 8
    r = random.Random(240923)
    masks = list(PILOT_MASKS) + [r.randrange(MAX_MASK + 1) for _ in range(128)]
    vals = [0, 1, 0xffffffff, 0x55555555, 0xaaaaaaaa, 0x80000000]
    vals.extend(r.getrandbits(32) for _ in range(256))
    for mask in masks:
        for a in vals:
            assert model(mask, a) == python_oracle(a), (mask, a)
    print(f'PASS: {len(masks)} architectural masks × {len(vals)} input vectors')
    print('NOTE: this is a Python-model test, not HDL simulation or formal proof')


if __name__ == '__main__':
    run()
