"""Zero-EDA additive scaffold for a NEW benchmark: popcount32_tree.

Never changes the existing popcount32 reference, results, policy or grammar.
Creates a distinct benchmark so exploratory pilot outcomes cannot contaminate
completed cross-family results. Do not launch EDA until scaffold and smoke pass.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from chiprl.popcount_tree_generator import NAME, PILOT_MASKS, render

ROOT = Path(__file__).resolve().parents[1]
ORIGINAL = 'popcount32'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def create(path: Path, content: str):
    if path.exists():
        if path.read_text() == content:
            print('PRESENT', path.relative_to(ROOT))
            return
        raise FileExistsError(f'Existing file differs; refusing overwrite: {path}')
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)
    print('CREATE', path.relative_to(ROOT))


def scaffold():
    p = ROOT / 'chiprl/benchmarks.py'
    data = p.read_text()
    marker = '    "priority32": Benchmark('
    assert data.count(marker) == 1, 'expected original registry entry missing'
    if '    "popcount32_tree": Benchmark(' not in data:
        block = '''    "popcount32_tree": Benchmark(
        name="popcount32_tree",
        top_module="popcount32_tree",
        reference_top="popcount32_tree_ref",
        testbench=ROOT / "sim/tb_popcount32_tree.sv",
        reference=ROOT / "rtl/reference/popcount32_tree_ref.v",
        orfs_config_host=ROOT / "orfs/popcount32_tree/config.mk",
        orfs_config_container="/work/orfs/popcount32_tree/config.mk",
        sdc=ROOT / "orfs/popcount32_tree/constraint.sdc",
        pass_marker="PASS popcount32_tree randomized+protocol",
    ),
'''
        p.write_text(data.replace(marker, block + marker, 1))
        print('UPDATE', p.relative_to(ROOT))
    else:
        print('PRESENT', p.relative_to(ROOT), '(new benchmark)')
    files = {
        'rtl/reference/popcount32_tree_ref.v':
            (ROOT / 'rtl/reference/popcount32_ref.v').read_text().replace(
                'module popcount32_ref (', 'module popcount32_tree_ref (', 1
            ),
        'sim/tb_popcount32_tree.sv':
            (ROOT / 'sim/tb_popcount32.sv').read_text().replace(
                'popcount32 dut (.*);', 'popcount32_tree dut (.*);', 1
            ).replace('PASS popcount32 randomized+protocol',
                      'PASS popcount32_tree randomized+protocol'),
        'orfs/popcount32_tree/config.mk':
            (ROOT / 'orfs/popcount32/config.mk').read_text().replace(
                'popcount32', 'popcount32_tree'
            ),
        'orfs/popcount32_tree/constraint.sdc':
            (ROOT / 'orfs/popcount32/constraint.sdc').read_text().replace(
                'popcount32', 'popcount32_tree'
            ),
        'rtl/popcount32_tree/baseline.v': render(0),
    }
    for rel, contents in files.items():
        create(ROOT / rel, contents)
    for mask in PILOT_MASKS:
        p = ROOT / 'rtl/generated/popcount32_tree_arch_seed' / f'mask_{mask:08x}.v'
        create(p, render(mask))
    protocol = {
        'experiment': 'popcount32_tree_architecture_pilot_v1',
        'stage': 'exploratory_diversity_gate_before_any_v3_search',
        'benchmark': NAME,
        'tree_levels': 5,
        'decisions': 31,
        'action_space': '2**31 masks; 0=sized addition, 1=explicit parallel carry lookahead at node',
        'node_bit_order': 'bottom up; 16, 8, 4, 2, 1 nodes at ascending mask bits',
        'seed_masks': [f'0x{m:08x}' for m in PILOT_MASKS],
        'physical_setup': 'unchanged Nangate45, 10ns, 100x100 die, core 5:5:95:95, density 0.2',
        'reward': 'frozen proxy_reward_v0 = -0.001*area + 10*WNS',
        'gate': {
            'all_eight_functional_formal_routed': True,
            'minimum_distinct_rounded_physical_pairs': 4,
            'area_round_dp': 2,
            'wns_round_dp': 3,
            'minimum_reward_span': 0.10,
            'minimum_distinct_rounded_areas': 3,
            'area_distinct_round_dp': 1,
            'minimum_relative_area_span': 0.01,
        },
        'if_gate_fails': 'stop; report exploratory negative result; no v3 RL experiment on this grammar',
        'no_initial_policy_or_runner_tuning_from_pilot': True,
        'core_algorithm_sources_not_modified': True,
        'provisional_future_methods': ['v2_legacy', 'v2_raw_aggregate', 'v3_conditioned', 'v2_frozen'],
        'pilot_validity_warning': 'The gate requires area diversity AND scalar-reward variation; nontrivial physical diversity remains a necessary but not sufficient learning condition.',
    }
    proto = ROOT / 'experiments/protocol_popcount_tree_arch_pilot_v1.json'
    create(proto, json.dumps(protocol, indent=2, sort_keys=True) + '\n')
    print('PASS: scaffold; preregister/commit before any new benchmark PPA')


def verify():
    from chiprl.benchmarks import get_benchmark
    from chiprl.popcount_tree_generator import render
    bench = get_benchmark(NAME)
    assert bench.top_module == NAME
    assert bench.formal_seq == 4
    assert len(PILOT_MASKS) == 8 and len(set(PILOT_MASKS)) == 8
    for mask in PILOT_MASKS:
        s = render(mask)
        assert s.count('// node ') == 31
        assert 'y_o <=' in s
        path = ROOT / 'rtl/generated/popcount32_tree_arch_seed' / f'mask_{mask:08x}.v'
        assert s == path.read_text()
    assert render(0) == (ROOT / 'rtl/popcount32_tree/baseline.v').read_text()
    assert (ROOT / 'sim/tb_popcount32_tree.sv').read_text().count('popcount32_tree dut') == 1
    assert (ROOT / 'rtl/reference/popcount32_tree_ref.v').read_text().count('module popcount32_tree_ref') == 1
    print('PASS: 8 unique, reproducible RTL variants; no EDA executed')


if __name__ == '__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('command', choices=('scaffold','verify'))
    args=parser.parse_args()
    scaffold() if args.command == 'scaffold' else verify()
