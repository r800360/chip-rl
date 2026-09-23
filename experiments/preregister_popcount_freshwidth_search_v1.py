"""Freeze the completed 16/64-bit seed corpora AND preregister the search.

No EDA. No post-search tuning. Does not rewrite previously frozen code.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
from pathlib import Path

from chiprl.benchmarks import ROOT
from chiprl.popcount_tree_widths_v1 import FRESH_WIDTHS, name, pilot_masks, mask_digits
from chiprl.rl_env import is_valid_result
from experiments.popcount_tree_freshwidth_pilot_v1 import verify as verify_pilot
from experiments.popcount_freshwidth_search_v1 import METHODS, RNG_SEEDS, BUDGET

PILOT = ROOT / 'experiments/protocol_popcount_tree_freshwidth_pilot_v1.json'
PREVIOUS = ROOT / 'experiments/protocol_popcount_tree_v3_v1.json'
FREEZE = ROOT / 'experiments/popcount_freshwidth_seed_freeze_v1.json'
PROTOCOL = ROOT / 'experiments/protocol_popcount_freshwidth_search_v1.json'

SOURCE_PATHS = (
    'chiprl/autoregressive_policy.py',
    'chiprl/benchmarks.py',
    'chiprl/conditioned_autoregressive_policy.py',
    'chiprl/conditioned_policy_gradient.py',
    'chiprl/evaluate.py',
    'chiprl/popcount_tree_generator.py',
    'chiprl/popcount_tree_widths_v1.py',
    'chiprl/rl_env.py',
    'experiments/popcount_tree_freshwidth_pilot_v1.py',
    'experiments/popcount_freshwidth_search_v1.py',
    'experiments/preregister_popcount_freshwidth_search_v1.py',
    'experiments/smoke_popcount_freshwidth_search_v1.py',
    'experiments/run_popcount_freshwidth_search_v1.sh',
)


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def jread(path: Path):
    return json.loads(path.read_text())


def save_new(path: Path, data):
    if path.exists():
        raise RuntimeError(f'Existing freeze/protocol: {path}. Verify instead of overwriting.')
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + '\n')


def audit_seed_corpus(width: int):
    nm = name(width)
    base = ROOT / f'results/{nm}_arch_seed_v1'
    resultfile = base / 'results.json'
    summaryfile = base / 'summary.json'
    frontierfile = base / 'frontier.json'
    baselinefile = ROOT / f'results/popcount_freshwidth_baseline_v1/{nm}.json'
    rows = jread(resultfile)
    s = jread(summaryfile)
    baseline = jread(baselinefile)
    pilot = jread(PILOT)
    masks = list(pilot_masks(width))
    if len(rows) != 8 or [int(r['boundary_mask']) for r in rows] != masks:
        raise RuntimeError(f'{nm}: seed masks/ordering differ from preregistration')
    if not all(is_valid_result(r) and r['synthesis_ok'] and r['cache_hit'] is False for r in rows):
        raise RuntimeError(f'{nm}: one or more invalid/cached seeds')
    if not s['gate_passed'] or not s['eight_valid_uncached']:
        raise RuntimeError(f'{nm}: preregistered diversity gate did not pass')
    if s['results_sha256'] != sha(resultfile) or s['pilot_protocol_sha256'] != sha(PILOT):
        raise RuntimeError(f'{nm}: summary/results/protocol hash mismatch')
    if not (is_valid_result(baseline) and baseline['cache_hit'] is False
            and baseline['pilot_protocol_sha256'] == sha(PILOT)):
        raise RuntimeError(f'{nm}: invalid baseline')
    fp0 = rows[0]['fingerprint']
    fp_keys = ('schema_version', 'benchmark', 'top_module', 'testbench_sha256',
               'reference_rtl_sha256', 'orfs_config_sha256', 'sdc_sha256',
               'formal_seq', 'or_image_id', 'orfs_git_commit', 'verilator')
    for r in rows:
        fp = r['fingerprint']
        if any(fp[k] != fp0[k] for k in fp_keys):
            raise RuntimeError(f'{nm}: inconsistent physical evaluation fingerprints')
        if r['pilot_protocol_sha256'] != sha(PILOT):
            raise RuntimeError(f'{nm}: row protocol drift')
        m = int(r['boundary_mask'])
        path = ROOT / f'rtl/generated/{nm}_arch_seed_v1/mask_{m:0{mask_digits(width)}x}.v'
        if fp['rtl_sha256'] != sha(path):
            raise RuntimeError(f'{nm}: candidate RTL hash mismatch: {m:#x}')
        reward = -0.001 * r['area'] + 10.0 * r['wns']
        if abs(reward - r['proxy_reward_v0']) > 1e-5:
            raise RuntimeError(f'{nm}: reward changed at mask {m:#x}')
    if any(baseline['fingerprint'][k] != fp0[k] for k in fp_keys):
        raise RuntimeError(f'{nm}: baseline and shared-seed fingerprint mismatch')
    if set(int(r['boundary_mask']) for r in jread(frontierfile)) - set(masks):
        raise RuntimeError(f'{nm}: frontier contains a non-seed mask')
    gate = pilot['gate']
    sig = {(round(r['area'],gate['area_round_dp']),
            round(r['wns'],gate['wns_round_dp'])) for r in rows}
    ar = {round(r['area'],gate['area_distinct_round_dp']) for r in rows}
    span = (max(r['area'] for r in rows) - min(r['area'] for r in rows)) / min(r['area'] for r in rows)
    rewspan = max(r['proxy_reward_v0'] for r in rows) - min(r['proxy_reward_v0'] for r in rows)
    gate_ok = (len(sig) >= gate['minimum_distinct_rounded_physical_pairs'] and
               len(ar) >= gate['minimum_distinct_rounded_areas'] and
               span >= gate['minimum_relative_area_span'] and
               rewspan >= gate['minimum_reward_span'])
    if not gate_ok or len(sig) != s['distinct_signatures'] or abs(span-s['relative_area_span']) > 1e-12:
        raise RuntimeError(f'{nm}: independently recomputed diversity gate failed')
    best = max(rows, key=lambda r: r['proxy_reward_v0'])
    return {
        'gate_passed': True,
        'seed_count': 8,
        'seed_masks': [f'0x{m:0{mask_digits(width)}x}' for m in masks],
        'best_seed_mask': best['mask'],
        'best_seed_reward': best['proxy_reward_v0'],
        'physical_signatures': len(sig),
        'relative_area_span': span,
        'reward_span': rewspan,
        'source_fingerprint': {k: fp0[k] for k in fp_keys},
        'results_sha256': sha(resultfile),
        'summary_sha256': sha(summaryfile),
        'frontier_sha256': sha(frontierfile),
        'baseline_sha256': sha(baselinefile),
    }


def prior_source_guard():
    old = jread(PREVIOUS)['source_sha256']
    for rel in ('chiprl/autoregressive_policy.py', 'chiprl/benchmarks.py',
                'chiprl/conditioned_autoregressive_policy.py',
                'chiprl/conditioned_policy_gradient.py', 'chiprl/evaluate.py',
                'chiprl/popcount_tree_generator.py', 'chiprl/rl_env.py'):
        if sha(ROOT / rel) != old[rel]:
            raise RuntimeError(f'Historical v3 source was changed: {rel}')


def verify():
    verify_pilot()
    prior_source_guard()
    freeze = jread(FREEZE)
    proto = jread(PROTOCOL)
    if proto['pilot_protocol_sha256'] != sha(PILOT) or proto['seed_freeze_sha256'] != sha(FREEZE):
        raise RuntimeError('Frozen protocol dependency drift')
    if (proto['widths'] != list(FRESH_WIDTHS) or proto['methods'] != list(METHODS)
            or proto['rng_seeds'] != list(RNG_SEEDS) or proto['budget_per_run'] != BUDGET):
        raise RuntimeError('Search hyperparameters differ from preregistration')
    for rel, digest in proto['source_sha256'].items():
        if sha(ROOT / rel) != digest:
            raise RuntimeError(f'Source changed since preregistration: {rel}')
    for width in FRESH_WIDTHS:
        nm = name(width)
        current = audit_seed_corpus(width)
        if freeze['widths'][nm] != current:
            raise RuntimeError(f'{nm}: frozen seed data changed')
        print(f'PASS {nm}: seed={current["best_seed_mask"]} reward={current["best_seed_reward"]:.6f} '
              f'physical_signatures={current["physical_signatures"]}')
    print('PASS: frozen 16/64-bit seed corpora + source-fingerprinted search protocol; no EDA')


def freeze():
    if FREEZE.exists() or PROTOCOL.exists():
        raise RuntimeError('Freeze/protocol already exists; use --verify')
    verify_pilot()
    prior_source_guard()
    for width in FRESH_WIDTHS:
        nm = name(width)
        root = ROOT / f'results/rl_runs/{nm}'
        if list(root.glob('freshwidth_search_v1_*/state.json')):
            raise RuntimeError(f'Search data already present at {nm}; cannot preregister now')
    corpora = {name(w): audit_seed_corpus(w) for w in FRESH_WIDTHS}
    freeze_doc = {
        'experiment': 'popcount_freshwidth_global_local_v1',
        'status': 'SEEDS_FROZEN_BEFORE_SEARCH',
        'source_commit_before_search': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
        'pilot_protocol_sha256': sha(PILOT),
        'widths': corpora,
    }
    save_new(FREEZE, freeze_doc)
    protocol = {
        'experiment': 'popcount_freshwidth_global_local_v1',
        'stage': 'AFTER_EIGHT_SEEDS_EACH_AND_BEFORE_ANY_NEW_SEARCH',
        'pilot_protocol_sha256': sha(PILOT),
        'seed_freeze_sha256': sha(FREEZE),
        'widths': list(FRESH_WIDTHS),
        'methods': list(METHODS),
        'rng_seeds': list(RNG_SEEDS),
        'budget_per_run': BUDGET,
        'logical_query_count': len(FRESH_WIDTHS)*len(METHODS)*len(RNG_SEEDS)*BUDGET,
        'global_policy': 'Frozen 32-bit conditioned-v3 policy structure/learning defaults; width-specific seed initialization',
        'uniform_local': 'Uniform choice among previously unseen one-bit flips of the highest-reward own valid archive design with an unseen neighbor; deterministic reward/area/mask tie break',
        'hybrid_schedule': 'query indices 0,2,... local; indices 1,3,... global; fixed 50/50 allocation',
        'hybrid_learning_rule': 'v3_conditioned updates only after own global-policy proposals; local proposals update own candidate archive, not global-policy parameters',
        'frozen_hybrid_control': 'same initial policy, deterministic proposal mixture and adaptive own local archive, but no parameter updates',
        'reward': '-0.001*area + 10*WNS; invalid evaluated candidates consume one logical query',
        'rng_rule': 'random.Random(seed*1000 + query_index*4 + channel), channel=1(local),2(global)',
        'between_run_isolation': 'only eight preregistered seed results are shared; each method receives only its own subsequent results; global physical cache can be shared',
        'primary': ['paired v3_hybrid minus frozen_hybrid final seed-relative reward by (width,RNG seed)',
                    'paired v3_global minus uniform_local final seed-relative reward by (width,RNG seed)'],
        'secondary': ['v3_hybrid minus v3_global', 'first improvement query (no improvement censored at 17)',
                      'incumbent trajectory AUC', 'Pareto-frontier contributions', 'local/global K and cache hits',
                      'policy snapshots and acceptance mass'],
        'limitations': ['two widths of the same popcount family, chosen after prior 32-bit exploratory outcomes',
                        'one trajectory per method×width×seed; do not generalize to all RTL tasks',
                        'seed incumbents are known from shared-seed pilot; no search results observed when preregistering'],
        'source_sha256': {rel: sha(ROOT / rel) for rel in SOURCE_PATHS},
    }
    save_new(PROTOCOL, protocol)
    verify()
    print('CREATE', FREEZE.relative_to(ROOT), PROTOCOL.relative_to(ROOT))


def main():
    p = argparse.ArgumentParser(description=__doc__)
    group = p.add_mutually_exclusive_group(required=True)
    group.add_argument('--freeze', action='store_true')
    group.add_argument('--verify', action='store_true')
    args = p.parse_args()
    freeze() if args.freeze else verify()

if __name__ == '__main__':
    main()
