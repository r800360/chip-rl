"""Measure EXACTLY eight fixed, preregistered popcount-tree architectures.

Exploratory diversity gate: no RL search is permitted unless the original
pre-measurement diversity thresholds pass. A failed evaluation is preserved
and stops the run; a second call only resumes untouched remaining seeds.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from chiprl.benchmarks import ROOT, get_benchmark
from chiprl.evaluate import evaluate
from chiprl.popcount_tree_generator import NAME, PILOT_MASKS, write_candidate
from chiprl.rl_env import pareto_front

PROTO = ROOT / 'experiments/protocol_popcount_tree_arch_pilot_v1.json'
OUT = ROOT / 'results/popcount32_tree_arch_seed'
RESULTS = OUT / 'results.json'
SOURCE_KEYS = ('schema_version', 'benchmark', 'top_module', 'testbench_sha256',
               'reference_rtl_sha256', 'orfs_config_sha256', 'sdc_sha256',
               'formal_seq', 'or_image_id', 'orfs_git_commit', 'verilator')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load():
    proto = json.loads(PROTO.read_text())
    expected = [int(x, 0) for x in proto['seed_masks']]
    assert tuple(expected) == PILOT_MASKS
    rows = json.loads(RESULTS.read_text()) if RESULTS.exists() else []
    assert len(rows) <= len(PILOT_MASKS)
    assert [int(r['boundary_mask']) for r in rows] == expected[:len(rows)], (
        'Seed order or saved masks changed; STOP'
    )
    assert all(r['protocol_sha256'] == sha(PROTO) for r in rows), (
        'Protocol changed during measurements; STOP'
    )
    return proto, rows


def valid(r):
    return (r.get('functional') is True and r.get('formal_ok') is True
            and r.get('synthesis_ok') is True and r.get('place_route_ok') is True
            and r.get('area') is not None and r.get('wns') is not None
            and r.get('proxy_reward_v0') is not None)


def save(rows):
    OUT.mkdir(parents=True, exist_ok=True)
    temp = RESULTS.with_suffix('.json.tmp')
    temp.write_text(json.dumps(rows, sort_keys=True, indent=2) + '\n')
    temp.replace(RESULTS)


def report():
    proto, rows = load()
    if len(rows) != len(PILOT_MASKS):
        raise RuntimeError(f'{len(rows)}/8 seed results present: finish pilot first')
    assert all(valid(r) for r in rows), 'Invalid candidate: preserve and investigate'
    ref = rows[0]['fingerprint']
    bench = get_benchmark(NAME)
    file_fingerprints = {
        'testbench_sha256': sha(bench.testbench),
        'reference_rtl_sha256': sha(bench.reference),
        'orfs_config_sha256': sha(bench.orfs_config_host),
        'sdc_sha256': sha(bench.sdc),
    }
    for r in rows:
        for key in SOURCE_KEYS:
            assert r['fingerprint'][key] == ref[key], f'{key} fingerprint mismatch'
        for key, value in file_fingerprints.items():
            assert r['fingerprint'][key] == value, f'{key} source changed'
        assert not r.get('cache_hit'), 'Pilot physical result must be uncached'
        mask = int(r['boundary_mask'])
        rtl = ROOT / 'rtl/generated/popcount32_tree_arch_seed' / f'mask_{mask:08x}.v'
        assert r['fingerprint']['rtl_sha256'] == sha(rtl)
    g = proto['gate']
    signatures = {(round(r['area'], g['area_round_dp']),
                   round(r['wns'], g['wns_round_dp'])) for r in rows}
    spread = max(r['proxy_reward_v0'] for r in rows) - min(r['proxy_reward_v0'] for r in rows)
    distinct_areas = {round(r['area'], g['area_distinct_round_dp']) for r in rows}
    relative_area_span = (max(r['area'] for r in rows) - min(r['area'] for r in rows)) / min(r['area'] for r in rows)
    passed = (len(signatures) >= g['minimum_distinct_rounded_physical_pairs']
              and len(distinct_areas) >= g['minimum_distinct_rounded_areas']
              and relative_area_span >= g['minimum_relative_area_span']
              and spread >= g['minimum_reward_span'])
    frontier = pareto_front(rows)
    (OUT / 'frontier.json').write_text(json.dumps(frontier, indent=2, sort_keys=True) + '\n')
    summary = {
        'benchmark': NAME,
        'stage': 'exploratory_grammar_diversity',
        'count': len(rows), 'valid': len(rows),
        'distinct_physical_signatures': len(signatures),
        'distinct_rounded_areas': len(distinct_areas),
        'relative_area_span': relative_area_span,
        'reward_span': spread,
        'seed_best_reward': max(r['proxy_reward_v0'] for r in rows),
        'seed_best_mask': max(rows, key=lambda r: r['proxy_reward_v0'])['mask'],
        'frontier_size': len(frontier), 'diversity_gate_passed': passed,
        'protocol_sha256': sha(PROTO), 'results_sha256': sha(RESULTS),
        'predeclared_gate': g,
    }
    (OUT / 'summary.json').write_text(json.dumps(summary, indent=2, sort_keys=True) + '\n')
    for row in rows:
        print(f"{row['mask']} area={row['area']:.3f} WNS={row['wns']:.5f} reward={row['proxy_reward_v0']:.6f}")
    print(f"Distinct rounded physical signatures: {len(signatures)}/8")
    print(f"Area variation: {relative_area_span*100:.2f}%, distinct areas: {len(distinct_areas)}")
    print(f"Reward span: {spread:.6f}, Pareto points: {len(frontier)}")
    print('DIVERSITY GATE:', 'PASS' if passed else 'FAIL; STOP before RL search')
    return passed


def run():
    proto, rows = load()
    if any(not valid(r) for r in rows):
        raise RuntimeError('Previously recorded seed failed: STOP, no automatic rerun')
    OUT.mkdir(parents=True, exist_ok=True)
    if len(rows) == len(PILOT_MASKS):
        print('Pilot already completed; no new EDA')
        return report()
    for i, mask in enumerate(PILOT_MASKS[len(rows):], start=len(rows) + 1):
        candidate = ROOT / 'rtl/generated/popcount32_tree_arch_seed' / f'mask_{mask:08x}.v'
        from chiprl.popcount_tree_generator import render
        assert candidate.read_text() == render(mask), f'Generated RTL drift: {candidate}'
        result = dict(evaluate(candidate, benchmark=NAME, cache=False, clean=True))
        result.update(boundary_mask=mask, mask=f'0x{mask:08x}',
                      architecture='balanced_tree_add_or_CLA',
                      protocol_sha256=sha(PROTO))
        rows.append(result)
        save(rows)
        print(f'SEED {i}/8 {result["mask"]}: valid={valid(result)} '
              f'area={result.get("area")} WNS={result.get("wns")} '
              f'reward={result.get("proxy_reward_v0")}', flush=True)
        if not valid(result):
            raise RuntimeError('Invalid pilot seed recorded; preserve data and STOP')
    return report()


if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('--report-only', action='store_true')
    args = p.parse_args()
    if args.report_only:
        ok = report()
    else:
        ok = run()
    if not ok:
        raise SystemExit(2)
