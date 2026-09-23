"""No-EDA arithmetic and source-compatibility tests for the fresh-width generator."""
from __future__ import annotations

import random
from chiprl.popcount_tree_widths_v1 import (
    FRESH_WIDTHS, mask_bits, pilot_masks, render, name, reference, testbench,
)
from chiprl.popcount_tree_generator import PILOT_MASKS, render as old_render


def cla_add(a: int, b: int, width: int) -> int:
    p = [(a >> i & 1) ^ (b >> i & 1) for i in range(width)]
    g = [(a >> i & 1) & (b >> i & 1) for i in range(width)]
    result = p[0]
    for bit in range(1, width + 1):
        carry = 0
        for generated in range(bit - 1, -1, -1):
            term = g[generated]
            for propagated in range(generated + 1, bit):
                term &= p[propagated]
            carry |= term
        if bit < width:
            result |= (p[bit] ^ carry) << bit
        else:
            result |= carry << width
    return result


def oracle_tree(width: int, mask: int, value: int) -> int:
    nodes = [(value >> i) & 1 for i in range(width)]
    node_index = 0
    for level in range(width.bit_length() - 1):
        next_nodes = []
        for pair in range(len(nodes) // 2):
            a, b = nodes[2 * pair:2 * pair + 2]
            result = (cla_add(a, b, level + 1)
                      if mask & (1 << node_index) else a + b)
            next_nodes.append(result)
            node_index += 1
        nodes = next_nodes
    assert node_index == mask_bits(width)
    return nodes[0]


def main():
    rng = random.Random(20260923)
    n = 0
    for w in range(1, 6):
        for a in range(1 << w):
            for b in range(1 << w):
                assert cla_add(a, b, w) == a + b
                n += 1
    for _ in range(10000):
        a = rng.randrange(64)
        b = rng.randrange(64)
        assert cla_add(a, b, 6) == a + b
        n += 1
    for mask in PILOT_MASKS:
        assert render(32, mask) == old_render(mask)
    print("PASS exact byte-for-byte 32-bit RTL compatibility for all historical pilot masks")
    for width in FRESH_WIDTHS:
        masks = list(pilot_masks(width))
        masks += [rng.getrandbits(mask_bits(width)) for _ in range(80)]
        vectors = [0, 1, (1 << width) - 1, 1 << (width - 1)]
        vectors += [rng.getrandbits(width) for _ in range(128)]
        for mask in masks:
            rtl = render(width, mask)
            assert rtl.count("// node ") == width - 1
            for x in vectors:
                assert oracle_tree(width, mask, x) == x.bit_count()
        assert f"module {name(width)}_ref" in reference(width)
        assert f"PASS {name(width)} randomized+protocol" in testbench(width)
        print(f"PASS {name(width)}: {len(masks)} masks x {len(vectors)} oracle inputs")
    print(f"PASS: exhaustive CLA math + {n} cases, zero EDA; physical diversity untested")


if __name__ == "__main__":
    main()
