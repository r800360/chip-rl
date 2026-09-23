"""Create fixed 31-mask RTL corpus and immutable pre-measurement protocol; zero EDA."""
from __future__ import annotations

import argparse
from chiprl.benchmarks import ROOT
from chiprl.popcount_tree_generator import render
from experiments.popcount_tree_oneflip_common_v1 import (
    MASKS, OUT, PROTO, RESULTS, RTL_DIR, candidate_path,
    jdumps, protocol_data, verify_protocol_and_rtl,
)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--verify', action='store_true', help='Read-only preregistration and RTL audit')
    args = p.parse_args()
    if args.verify:
        protocol = verify_protocol_and_rtl()
        print('PASS: frozen preregistration and 31 RTL hashes, no EDA')
        print('Protocol:', PROTO.relative_to(ROOT))
        return
    if RESULTS.exists() or list(OUT.glob('*.json')):
        raise RuntimeError('Prior neighborhood result records exist: do not preregister after measurements')
    RTL_DIR.mkdir(parents=True, exist_ok=True)
    for i, mask in enumerate(MASKS):
        path = candidate_path(i)
        contents = render(mask)
        if path.exists() and path.read_text() != contents:
            raise RuntimeError(f'Cannot overwrite differing candidate RTL: {path}')
        if not path.exists():
            path.write_text(contents)
    protocol = protocol_data()
    contents = jdumps(protocol)
    if PROTO.exists():
        if PROTO.read_text() != contents:
            raise RuntimeError('Cannot overwrite previously generated protocol')
    else:
        PROTO.write_text(contents)
    verify_protocol_and_rtl()
    print('PASS: 31 unique K=30 one-flip neighbors generated, zero EDA')
    print('PASS: frozen seed corpus, v3 protocol, source fingerprints and new RTL verified')
    print('Preregistration:', PROTO.relative_to(ROOT))
    print('NEXT: commit/tag protocol, both scripts and ALL 31 generated RTLs BEFORE measuring')


if __name__ == '__main__':
    main()
