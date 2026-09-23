"""Frozen inputs and validation for the 31-neighbor popcount-tree sweep.

This is a deterministic, non-adaptive exploratory landscape study, NOT RL.
No functions here invoke EDA.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

from chiprl.benchmarks import ROOT, get_benchmark
from chiprl.popcount_tree_generator import BITS, MAX_MASK, render

NAME = 'popcount32_tree'
PROTO = ROOT / 'experiments/protocol_popcount_tree_oneflip_v1.json'
OLD_PROTO = ROOT / 'experiments/protocol_popcount_tree_v3_v1.json'
SEED_FREEZE = ROOT / 'experiments/popcount_tree_arch_seed_freeze_v1.json'
SEED_RESULTS = ROOT / 'results/popcount32_tree_arch_seed/results.json'
PREVIOUS_BUNDLE = ROOT / 'results/popcount_tree_v3_pilot_v1/popcount_tree_v3_results_bundle.zip'
RTL_DIR = ROOT / 'rtl/generated/popcount32_tree_oneflip_v1'
OUT = ROOT / 'results/popcount_tree_oneflip_v1'
RESULTS = OUT / 'results.json'
TAG = 'popcount-tree-oneflip-preregistered-v1'
assert BITS == 31 and MAX_MASK == 0x7FFFFFFF
MASKS = tuple(MAX_MASK ^ (1 << i) for i in range(BITS))
SOURCE_FILES = (
    'chiprl/benchmarks.py', 'chiprl/evaluate.py',
    'chiprl/popcount_tree_generator.py',
    'experiments/popcount_tree_oneflip_common_v1.py',
    'experiments/preregister_popcount_tree_oneflip_v1.py',
    'experiments/run_popcount_tree_oneflip_v1.py',
    'rtl/reference/popcount32_tree_ref.v',
    'sim/tb_popcount32_tree.sv',
    'orfs/popcount32_tree/config.mk',
    'orfs/popcount32_tree/constraint.sdc',
)
FINGERPRINT_FIELDS = (
    'schema_version', 'benchmark', 'top_module',
    'testbench_sha256', 'reference_rtl_sha256',
    'orfs_config_sha256', 'sdc_sha256', 'formal_seq',
    'or_image', 'or_image_id', 'orfs_git_commit', 'verilator',
)


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def jload(path: Path):
    return json.loads(path.read_text())


def jdumps(obj) -> str:
    return json.dumps(obj, indent=2, sort_keys=True, allow_nan=False) + '\n'


def save_atomic(path: Path, obj):
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_suffix(path.suffix + '.tmp')
    temp.write_text(jdumps(obj))
    temp.replace(path)


def candidate_path(i: int) -> Path:
    return RTL_DIR / f'mask_{MASKS[i]:08x}.v'


def valid(row) -> bool:
    return (row.get('functional') is True
            and row.get('formal_ok') is True
            and row.get('synthesis_ok') is True
            and row.get('place_route_ok') is True
            and all(isinstance(row.get(x), (int, float)) and
                    not isinstance(row.get(x), bool)
                    for x in ('area', 'wns', 'proxy_reward_v0')))


def frozen_inputs():
    old = jload(OLD_PROTO)
    freeze = jload(SEED_FREEZE)
    assert PREVIOUS_BUNDLE.is_file(), 'Freeze previous v3 archive before preregistration'
    assert sha(PREVIOUS_BUNDLE) == '5cbad8da57c771d8dd133f5ddcc325349fd4ef572ab7d1d2756cf975cd3975a2', 'Previous v3 archive differs from completed study'
    rows = jload(SEED_RESULTS)
    assert sha(SEED_FREEZE) == old['seed_freeze_sha256'], 'Seed freeze differs from old v3 protocol'
    assert sha(SEED_RESULTS) == old['seed_results_sha256'] == freeze['results_sha256'], 'Seed corpus changed'
    assert freeze['diversity_gate_passed'] is True
    assert len(rows) == 8 and all(valid(r) for r in rows)
    assert [int(r['boundary_mask']) for r in rows] == [int(s, 0) for s in old['seed_masks']]
    assert rows[1]['boundary_mask'] == MAX_MASK
    incumbent = max(rows, key=lambda r: r['proxy_reward_v0'])
    assert int(incumbent['boundary_mask']) == MAX_MASK, 'Incumbent no longer all CLA'
    assert abs(incumbent['proxy_reward_v0'] - 71.474664) < 1e-9
    # Ensure the identical benchmark and evaluator versions are in use.
    for path in SOURCE_FILES:
        previous = old['source_sha256'].get(path)
        if previous is not None:
            assert sha(ROOT / path) == previous, f'Existing source changed since v3: {path}'
    b = get_benchmark(NAME)
    ref = rows[0]['fingerprint']
    for k, path in (
        ('testbench_sha256', b.testbench),
        ('reference_rtl_sha256', b.reference),
        ('orfs_config_sha256', b.orfs_config_host),
        ('sdc_sha256', b.sdc),
    ):
        assert sha(path) == ref[k], f'Benchmark source mismatch: {k}'
    for r in rows:
        for k in FINGERPRINT_FIELDS:
            assert r['fingerprint'][k] == ref[k], ('Seed fingerprint mismatch', k)
    assert sha(ROOT / 'chiprl/popcount_tree_generator.py') == old['source_sha256']['chiprl/popcount_tree_generator.py']
    return old, freeze, rows, incumbent


def protocol_data():
    old, freeze, rows, incumbent = frozen_inputs()
    assert len(set(MASKS)) == BITS
    assert all(m.bit_count() == 30 and (m ^ MAX_MASK).bit_count() == 1 for m in MASKS)
    return {
        'experiment': 'popcount32_tree_oneflip_v1',
        'stage': 'preregistered_before_all_new_physical_measurements',
        'kind': 'deterministic_nonadaptive_exhaustive_hamming_one_neighborhood',
        'benchmark': NAME,
        'incumbent_mask': f'0x{MAX_MASK:08x}',
        'incumbent_reward': incumbent['proxy_reward_v0'],
        'neighbor_count': BITS,
        'node_order': 'i=0..30; bit0-15 lowest tree level, bit30 root',
        'neighbor_masks': [f'0x{m:08x}' for m in MASKS],
        'excluded_masks': [f'0x{int(r["boundary_mask"]):08x}' for r in rows],
        'sequential_evaluation': 'one uncached clean EDA evaluation per neighbor in fixed i order',
        'failure_handling': 'record invalid evaluation and stop; do not replace, skip, or tune candidates',
        'primary': [
            'number of K=30 neighbors with reward above the frozen 31-boundary incumbent',
            'maximum seed-relative reward difference across all 31 valid neighbors',
        ],
        'secondary': [
            'complete area/WNS/reward table in bit-index order',
            'Pareto contributions relative to the eight original seed designs',
            'improvements by balanced-tree level',
            'functional/formal/route validity and cache status',
        ],
        'reward': 'frozen proxy_reward_v0 = -0.001*area + 10*wns for valid designs',
        'no_adaptation': True,
        'search_hypothesis': 'test whether previous policies failed to cover beneficial one-node deletions',
        'limitations': [
            'this neighborhood was chosen after inspecting exploratory v3 results',
            'observing it does not establish global optimality or RL superiority',
            'same benchmark and flow as previous popcount32_tree exploratory pilot',
        ],
        'prior_v3_protocol_sha256': sha(OLD_PROTO),
        'seed_freeze_sha256': sha(SEED_FREEZE),
        'seed_results_sha256': sha(SEED_RESULTS),
        'previous_v3_archive_sha256': sha(PREVIOUS_BUNDLE),
        'baseline_fingerprint': {k: rows[0]['fingerprint'][k] for k in FINGERPRINT_FIELDS},
        'candidate_sha256': {f'0x{m:08x}': hashlib.sha256(render(m).encode()).hexdigest()
                              for m in MASKS},
        'source_sha256': {path: sha(ROOT / path) for path in SOURCE_FILES},
    }


def verify_protocol_and_rtl():
    stored = jload(PROTO)
    expected = protocol_data()
    assert stored == expected, 'Frozen protocol or source/seed hashes changed; STOP'
    assert [int(s, 0) for s in stored['neighbor_masks']] == list(MASKS)
    assert len(stored['candidate_sha256']) == 31
    for i, mask in enumerate(MASKS):
        path = candidate_path(i)
        assert path.is_file(), f'Missing preregistered RTL {path}'
        assert path.read_text() == render(mask), f'RTL changed: {path}'
        assert sha(path) == stored['candidate_sha256'][f'0x{mask:08x}']
    return stored
