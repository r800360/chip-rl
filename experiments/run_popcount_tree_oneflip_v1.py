"""Run or report deterministic 31-point local sweep; no RL or adaptivity.

After preregistration is committed and tagged, run 31 uncached evaluations in fixed
node-index order. Every result is saved immediately. Invalid outcomes remain saved
and stop execution. Report-only never launches EDA.
"""
from __future__ import annotations

import argparse
import csv
import subprocess
from pathlib import Path

from chiprl.benchmarks import ROOT
from chiprl.popcount_tree_generator import MAX_MASK
from experiments.popcount_tree_oneflip_common_v1 import (
    FINGERPRINT_FIELDS, MASKS, OUT, PROTO, RESULTS, SEED_RESULTS, TAG,
    candidate_path, frozen_inputs, jload, save_atomic, sha, valid,
    verify_protocol_and_rtl,
)


def assert_tagged():
    tag_protocol = subprocess.run(
        ['git', 'show', f'{TAG}:experiments/{PROTO.name}'],
        cwd=ROOT, capture_output=True, check=False,
    )
    if tag_protocol.returncode != 0:
        raise RuntimeError(f'Missing preregistration tag {TAG}; commit/tag before PPA')
    if tag_protocol.stdout != PROTO.read_bytes():
        raise RuntimeError('Preregistration protocol differs from committed tag; STOP')
    # Verify that candidate RTLs were actually committed before measurement.
    for i in range(len(MASKS)):
        path = candidate_path(i)
        relative = path.relative_to(ROOT)
        stored = subprocess.run(
            ['git', 'show', f'{TAG}:{relative.as_posix()}'],
            cwd=ROOT, capture_output=True, check=False,
        )
        if stored.returncode != 0 or stored.stdout != path.read_bytes():
            raise RuntimeError(f'Candidate not frozen in tag: {relative}')


def load_saved(protocol, seeds):
    rows = jload(RESULTS) if RESULTS.exists() else []
    if len(rows) > 31:
        raise RuntimeError('More than 31 neighbor results recorded')
    assert [int(r['boundary_mask']) for r in rows] == list(MASKS[:len(rows)]), 'Order or mask mismatch'
    baseline = seeds[0]['fingerprint']
    for index, row in enumerate(rows):
        assert row['removed_bit'] == index, f'Wrong removed bit at index {index}'
        assert row['protocol_sha256'] == sha(PROTO), f'Protocol drift at index {index}'
        assert row['fingerprint']['rtl_sha256'] == sha(candidate_path(index)), 'RTL hash mismatch'
        for field in FINGERPRINT_FIELDS:
            assert row['fingerprint'][field] == baseline[field], ('Evaluator mismatch', index, field)
        if valid(row):
            actual = -0.001 * row['area'] + 10.0 * row['wns']
            assert abs(actual - row['proxy_reward_v0']) < 1e-4, f'Reward mismatch at {index}'
            assert row.get('cache_hit') is False, f'Expected uncached physical evaluation at {index}'
    return rows


def dominates(a, b):
    return (a['area'] <= b['area'] and a['wns'] >= b['wns']
            and (a['area'] < b['area'] or a['wns'] > b['wns']))


def report(protocol, seeds, incumbent, rows):
    if len(rows) != len(MASKS):
        raise RuntimeError(f'Incomplete sweep: {len(rows)}/31; finish or investigate')
    if not all(valid(r) for r in rows):
        raise RuntimeError('Invalid saved result: preserve and investigate, no auto-rerun')
    all_rows = [dict(r, source='frozen_seed') for r in seeds] + [
        dict(r, source='oneflip_sweep') for r in rows
    ]
    frontier = [r for r in all_rows
                if not any(dominates(other, r) for other in all_rows if other is not r)]
    # Different RTLs can yield identical PPA. Deduplicate signatures in report.
    frontier_signatures = set()
    distinct_frontier = []
    for r in sorted(frontier, key=lambda r: (r['area'], -r['wns'])):
        sig = (r['area'], r['wns'])
        if sig not in frontier_signatures:
            frontier_signatures.add(sig)
            distinct_frontier.append(r)
    improvements = [r for r in rows if r['proxy_reward_v0'] > incumbent['proxy_reward_v0'] + 1e-9]
    best = max(rows, key=lambda r: r['proxy_reward_v0'])
    seed_frontier_sigs = {(r['area'], r['wns']) for r in seeds
                          if not any(dominates(o, r) for o in seeds if o is not r)}
    summary = {
        'experiment': protocol['experiment'],
        'status': 'COMPLETE_DETERMINISTIC_EXPLORATORY_SWEEP',
        'protocol_sha256': sha(PROTO),
        'seed_results_sha256': sha(SEED_RESULTS),
        'neighbor_results_sha256': sha(RESULTS),
        'total_neighbors': len(rows),
        'valid_neighbors': len(rows),
        'uncached_evaluations': sum(not r.get('cache_hit') for r in rows),
        'incumbent_mask': f'0x{MAX_MASK:08x}',
        'incumbent_reward': incumbent['proxy_reward_v0'],
        'improving_neighbors': len(improvements),
        'best_neighbor_mask': best['mask'],
        'best_neighbor_reward': best['proxy_reward_v0'],
        'best_neighbor_delta': best['proxy_reward_v0'] - incumbent['proxy_reward_v0'],
        'pooled_frontier_physical_signatures': len(distinct_frontier),
        'new_frontier_physical_signatures': sum(r['source']=='oneflip_sweep'
                                                and (r['area'],r['wns']) not in seed_frontier_sigs
                                                for r in distinct_frontier),
    }
    # Fixed balanced-tree node index ranges, level 0 is the leaf-pair level.
    level_ranges = ((0, 16), (16, 24), (24, 28), (28, 30), (30, 31))
    summary['by_tree_level'] = {}
    for level, (lo, hi) in enumerate(level_ranges):
        subset = rows[lo:hi]
        summary['by_tree_level'][str(level)] = {
            'bit_indices': list(range(lo, hi)),
            'best_reward': max(r['proxy_reward_v0'] for r in subset),
            'improving': sum(r in improvements for r in subset),
        }
    save_atomic(OUT / 'summary.json', summary)
    save_atomic(OUT / 'pooled_frontier.json', distinct_frontier)
    with (OUT / 'results.csv').open('w', newline='') as fh:
        writer = csv.writer(fh)
        writer.writerow(('removed_bit', 'mask', 'area', 'wns', 'cells', 'power_w',
                         'proxy_reward_v0', 'delta_vs_seed', 'cache_hit'))
        for r in rows:
            writer.writerow((r['removed_bit'], r['mask'], r['area'], r['wns'],
                             r.get('cells'), r.get('power_w'), r['proxy_reward_v0'],
                             r['proxy_reward_v0']-incumbent['proxy_reward_v0'],r['cache_hit']))
    print('\n' + '='*76)
    print('COMPLETE: 31/31 K=30 one-flip neighbors, uncached and fully valid')
    print(f'Frozen 31-CLA seed: {incumbent["proxy_reward_v0"]:.6f}')
    print(f'Best neighbor {best["mask"]}: {best["proxy_reward_v0"]:.6f} '
          f'(delta {summary["best_neighbor_delta"]:+.6f})')
    print(f'Improving neighbors: {len(improvements)}/31')
    print(f'Pooled seed + one-flip physical Pareto signatures: {len(distinct_frontier)}')
    print('New frontier signatures contributed by one-flip:', summary['new_frontier_physical_signatures'])
    print('Summary:', (OUT / 'summary.json').relative_to(ROOT))
    print('Results:', (OUT / 'results.csv').relative_to(ROOT))
    return summary


def preflight():
    protocol = verify_protocol_and_rtl()
    assert_tagged()
    old, freeze, seeds, incumbent = frozen_inputs()
    rows = load_saved(protocol, seeds)
    return protocol, seeds, incumbent, rows


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--verify', action='store_true', help='Audit preregistration and saved prefix, no EDA')
    p.add_argument('--report-only', action='store_true', help='Create completed report, no EDA')
    p.add_argument('--run', action='store_true', help='Measure exactly 31 predetermined masks')
    args = p.parse_args()
    if sum((args.verify, args.report_only, args.run)) != 1:
        p.error('Select exactly one of --verify, --run, --report-only')
    protocol, seeds, incumbent, rows = preflight()
    if args.verify:
        print(f'PASS: tagged frozen protocol and all 31 RTLs; recorded {len(rows)}/31; no EDA')
        return
    if args.report_only:
        report(protocol, seeds, incumbent, rows)
        return
    if any(not valid(r) for r in rows):
        raise RuntimeError('Previously recorded failed evaluation; preserve data and STOP')
    if len(rows) == 31:
        print('Existing completed sweep: reporting without new EDA')
        report(protocol, seeds, incumbent, rows)
        return
    from chiprl.evaluate import evaluate, environment_manifest
    env = environment_manifest()
    ref = seeds[0]['fingerprint']
    for key in ('or_image', 'or_image_id', 'orfs_git_commit', 'verilator'):
        assert env[key] == ref[key], ('EDA tool environment changed; STOP', key)
    OUT.mkdir(parents=True, exist_ok=True)
    for i in range(len(rows), 31):
        mask = MASKS[i]
        path = candidate_path(i)
        print(f'[{i+1:02d}/31] bit={i:02d} mask=0x{mask:08x} K=30', flush=True)
        result = dict(evaluate(path.relative_to(ROOT), benchmark='popcount32_tree',
                               cache=False, clean=True))
        result.update(removed_bit=i, boundary_mask=mask, mask=f'0x{mask:08x}',
                      protocol_sha256=sha(PROTO),
                      exploratory_neighborhood='one_flip_from_31_CLA')
        rows.append(result)
        save_atomic(RESULTS, rows)
        # Also detect evaluator fingerprint drift and retain the failed record.
        load_saved(protocol, seeds)
        print(f'   valid={valid(result)} area={result.get("area")} WNS={result.get("wns")} '
              f'reward={result.get("proxy_reward_v0")} '
              f'delta={result.get("proxy_reward_v0",-1000)-incumbent["proxy_reward_v0"]:+.6f}',flush=True)
        if not valid(result):
            raise RuntimeError(f'Invalid result saved at bit {i}; preserve records and STOP')
    report(protocol, seeds, incumbent, rows)


if __name__ == '__main__':
    main()
