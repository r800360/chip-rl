"""Measure exactly eight preregistered masks; supports interruption without duplication."""
from __future__ import annotations

import argparse
import hashlib
import json
from functools import partial

from chiprl.benchmarks import ROOT
from chiprl.circuit_family_generators import FAMILIES, blocks_from_mask, write_candidate
from chiprl.evaluate import evaluate
from chiprl.rl_env import is_valid_result, pareto_front


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--benchmark', choices=FAMILIES, required=True)
    args = parser.parse_args()
    name = args.benchmark

    protocol_path = ROOT / 'experiments/protocol_crossfamily_v1.json'
    protocol = json.loads(protocol_path.read_text())
    protocol_hash = hashlib.sha256(protocol_path.read_bytes()).hexdigest()
    masks = [int(s, 0) for s in protocol['shared_seed_masks']]
    assert len(masks) == len(set(masks)) == 8

    out = ROOT / 'results' / f'{name}_shared_seed'
    rtl = ROOT / 'rtl/generated' / f'{name}_shared_seed'
    out.mkdir(parents=True, exist_ok=True)
    rtl.mkdir(parents=True, exist_ok=True)
    if (out / 'results.json').exists():
        raise SystemExit(f'{name} seed results already frozen; refusing overwrite')
    partial_path = out / 'partial_results.json'
    rows = json.loads(partial_path.read_text()) if partial_path.exists() else []
    assert len(rows) <= 8
    assert all(int(r['boundary_mask']) == masks[i] for i, r in enumerate(rows))
    assert all(r['protocol_sha256'] == protocol_hash for r in rows)
    assert all(is_valid_result(r) for r in rows)

    for i, mask in enumerate(masks[len(rows):], start=len(rows)):
        path = rtl / f'seed_{i:02d}_{mask:08x}.v'
        write_candidate(name, mask, path)
        result = evaluate(path, benchmark=name, cache=False, clean=True)
        result.update({
            'seed_index': i,
            'boundary_mask': mask,
            'mask': f'0x{mask:08x}',
            'blocks': blocks_from_mask(mask),
            'protocol_sha256': protocol_hash,
        })
        rows.append(result)
        partial_path.write_text(json.dumps(rows, indent=2, sort_keys=True) + '\n')
        print(f'{name} seed {i+1}/8: 0x{mask:08x} '
              f'valid={is_valid_result(result)} '
              f'area={result.get("area")} wns={result.get("wns")} '
              f'reward={result.get("proxy_reward_v0")}', flush=True)
        if not is_valid_result(result):
            raise RuntimeError(f'{name} seed {i+1} failed; preserve its result')

    front = pareto_front(rows)
    best = max(rows, key=lambda r: r['proxy_reward_v0'])
    (out / 'results.json').write_text(json.dumps(rows, indent=2, sort_keys=True) + '\n')
    (out / 'frontier.json').write_text(json.dumps(front, indent=2, sort_keys=True) + '\n')
    (out / 'summary.json').write_text(json.dumps({
        'benchmark': name, 'protocol_sha256': protocol_hash,
        'seed_count': 8, 'all_valid': True, 'pareto_count': len(front),
        'best_reward': best,
    }, indent=2, sort_keys=True) + '\n')
    partial_path.unlink(missing_ok=True)
    print('DONE', name, 'best=', best['mask'], best['proxy_reward_v0'])


if __name__ == '__main__':
    main()
