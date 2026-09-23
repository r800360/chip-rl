"""Preregister and validate 16x8 lane-sum tree, then measure eight frozen seeds.

Stages: scaffold -> verify -> hdl -> baseline -> seeds -> report.
Do not run physical measurements before committing protocol and generated RTL.
A failed gate ends this grammar's planned search; do not relax thresholds.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
from pathlib import Path

from chiprl.benchmarks import ROOT
from chiprl.evaluate import evaluate
from chiprl.formal import check_equivalence
from chiprl.rl_env import is_valid_result, pareto_front
from chiprl.lane_sum_tree_v1 import (
    NAME, PILOT_MASKS, BITS, benchmark, config, oracle, reference,
    render, sdc, testbench,
)

PROTOCOL = ROOT / 'experiments/protocol_lanesum_pilot_v1.json'
PRIOR = ROOT / 'experiments/protocol_popcount_freshwidth_search_v1.json'
BASELINE = ROOT / 'results/lanesum16x8_baseline_v1.json'
OUT = ROOT / 'results/lanesum16x8_arch_seed_v1'
RESULTS = OUT / 'results.json'
SUMMARY = OUT / 'summary.json'
FRONTIER = OUT / 'frontier.json'
SOURCE_PATHS = (
    'chiprl/lane_sum_tree_v1.py',
    'chiprl/learned_local_edit_v1.py',
    'experiments/lanesum_pilot_v1.py',
    'experiments/freeze_learned_local_v1.py',
    'experiments/learned_local_study_v1.py',
    'experiments/smoke_learned_local_v1.py',
    'experiments/summarize_learned_local_v1.py',
    'experiments/run_learned_local_v1.sh',
    'chiprl/evaluate.py',
    'chiprl/formal.py',
    'chiprl/benchmarks.py',
    'chiprl/autoregressive_policy.py',
    'chiprl/conditioned_autoregressive_policy.py',
    'chiprl/conditioned_policy_gradient.py',
    'chiprl/rl_env.py',
)
GATE = {
    'minimum_distinct_physical_pairs': 4,
    'area_pair_round_dp': 2,
    'wns_pair_round_dp': 3,
    'minimum_distinct_areas': 3,
    'area_distinct_round_dp': 1,
    'minimum_relative_area_span': 0.01,
    'minimum_reward_span': 0.10,
}
FP_FIELDS = (
    'schema_version', 'benchmark', 'top_module', 'testbench_sha256',
    'reference_rtl_sha256', 'orfs_config_sha256', 'sdc_sha256',
    'formal_seq', 'or_image_id', 'orfs_git_commit', 'verilator',
)


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def save(path: Path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_suffix(path.suffix+'.tmp')
    temp.write_text(json.dumps(data, sort_keys=True, indent=2) + '\n')
    temp.replace(path)


def source_guard():
    prior = json.loads(PRIOR.read_text())
    for rel, expect in prior['source_sha256'].items():
        path = ROOT / rel
        if sha(path) != expect:
            raise RuntimeError(f'Previously frozen source drifted: {rel}')


def generated_files() -> dict[str, str]:
    files = {
        f'rtl/reference/{NAME}_ref.v': reference(),
        f'sim/tb_{NAME}.sv': testbench(),
        f'orfs/{NAME}/config.mk': config(),
        f'orfs/{NAME}/constraint.sdc': sdc(),
        f'rtl/{NAME}/baseline.v': render(0),
    }
    for mask in PILOT_MASKS:
        files[f'rtl/generated/{NAME}_arch_seed_v1/mask_{mask:04x}.v'] = render(mask)
    return files


def scaffold():
    if PROTOCOL.exists():
        raise RuntimeError('Protocol exists: use verify, never overwrite a frozen protocol')
    source_guard()
    if BASELINE.exists() or RESULTS.exists() or (ROOT / f'results/rl_runs/{NAME}').exists():
        raise RuntimeError('New-family PPA or search records already exist: cannot preregister retroactively')
    generated = generated_files()
    for rel, body in generated.items():
        path = ROOT / rel
        if path.exists():
            if path.read_text() != body:
                raise RuntimeError(f'Existing generated source differs: {rel}')
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(body)
    protocol = {
        'experiment': 'lanesum16x8_architecture_pilot_v1',
        'status': 'REGISTERED_BEFORE_ANY_NEW_FAMILY_PPA',
        'family': 'sum of sixteen 8-bit unsigned lanes, eight from each 64-bit input',
        'relationship_to_prior': 'different functional datapath, shared arithmetic reduction topology and ADD/CLA operator grammar; not topology-independent generalization',
        'mask_order': 'bottom-up, left-to-right',
        'pilot_masks': [f'0x{m:04x}' for m in PILOT_MASKS],
        'rtl_hashes': {rel:hashlib.sha256(body.encode()).hexdigest() for rel,body in sorted(generated.items())},
        'prior_protocol_sha256': sha(PRIOR),
        'source_sha256': {rel:sha(ROOT/rel) for rel in SOURCE_PATHS},
        'eda': {'platform':'nangate45','period_ns':10.0,'die':'200x200','core':'[5,5,195,195]',
                'place_density':0.2,'cache':False,'clean':True,'reward':'-0.001*area + 10*WNS',
                'required_orfs_image_id': 'sha256:8cae1bdb8296eed70b4d981696b0f29aa7faeb61b64b1f2950506aaac65ef442',
                'required_orfs_commit':'3a964e13f11a4e435aac01ffa14db0a7d2853720'},
        'gate':GATE,
        'search_plan':{'methods':['v3_global','uniform_local','learned_local','frozen_hybrid','learned_hybrid'],
                       'rng_seeds':[33001,33002,33003], 'budget_per_run':16,
                       'primary':['paired learned_local - uniform_local','paired learned_hybrid - frozen_hybrid'],
                       'secondary':['v3_global - uniform_local', 'first improvement', 'Pareto contributions'],
                       'learning_hybrid_global_policy':'frozen corrected-v3 global sampler, local updates only'},
        'rules':['Gate failure stops new-family search without threshold adjustment',
                 'Search source is fixed before the family diversity pilot',
                 'The previously measured 16/32/64-bit popcount circuits are development data only'],
    }
    save(PROTOCOL, protocol)
    verify()
    print('REGISTERED lanesum16x8_tree, eight RTL seeds and 5-method search source (NO EDA)')


def verify():
    p = json.loads(PROTOCOL.read_text())
    source_guard()
    assert p['prior_protocol_sha256'] == sha(PRIOR)
    assert [int(m,0) for m in p['pilot_masks']] == list(PILOT_MASKS)
    assert p['gate'] == GATE
    for rel, expect in p['source_sha256'].items():
        assert sha(ROOT/rel) == expect, f'Changed source: {rel}'
    for rel, expect in p['rtl_hashes'].items():
        assert sha(ROOT/rel) == expect, f'Changed RTL/config/testbench: {rel}'
    for mask in PILOT_MASKS:
        r = render(mask)
        assert r.count('// node ') == BITS
        assert r.count('CLA\n') == mask.bit_count()
    assert oracle(0,0) == 0
    assert oracle((1<<64)-1,(1<<64)-1) == 4080
    print('PASS: unchanged prior source, new-family source and all 8 RTL/config fingerprints')
    return p


def require_tagged_preregistration():
    """Hard boundary: HDL/PPA only after the exact protocol is in a git tag."""
    tag = 'refs/tags/lanesum-pilot-protocol-v1'
    try:
        frozen = subprocess.check_output(
            ['git', 'show', f'{tag}:experiments/protocol_lanesum_pilot_v1.json'],
            cwd=ROOT, stderr=subprocess.DEVNULL,
        )
    except subprocess.CalledProcessError as ex:
        raise RuntimeError('STOP: commit and tag lanesum-pilot-protocol-v1 first') from ex
    if hashlib.sha256(frozen).hexdigest() != sha(PROTOCOL):
        raise RuntimeError('Tagged preregistration differs from working protocol; STOP')
    for rel in ('chiprl/lane_sum_tree_v1.py', 'chiprl/learned_local_edit_v1.py',
                'experiments/learned_local_study_v1.py'):
        try:
            data = subprocess.check_output(['git','show',f'{tag}:{rel}'],
                                           cwd=ROOT,stderr=subprocess.DEVNULL)
        except subprocess.CalledProcessError as ex:
            raise RuntimeError(f'Search source absent from preregistration tag: {rel}') from ex
        if hashlib.sha256(data).hexdigest() != sha(ROOT/rel):
            raise RuntimeError(f'Tagged source differs from working source: {rel}')



def hdl():
    verify()
    require_tagged_preregistration()
    import shutil
    if shutil.which('verilator') is None:
        raise RuntimeError('Verilator not available; execute on Ubuntu EDA machine')
    b = benchmark()
    for i, mask in enumerate(PILOT_MASKS,1):
        rtl = ROOT/f'rtl/generated/{NAME}_arch_seed_v1/mask_{mask:04x}.v'
        build = ROOT/f'.chiprl/lanesum_v1_hdl/mask_{mask:04x}'
        build.mkdir(parents=True, exist_ok=True)
        cmd = ['verilator','--binary','--timing','-Wall','-Wno-fatal',
               '--Mdir',str(build),str(rtl),str(b.testbench),'--top-module','tb']
        p = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
        if p.returncode:
            raise RuntimeError(f'HDL compile failure {mask:#x}:\n{p.stdout[-4000:]}\n{p.stderr[-4000:]}')
        q = subprocess.run([str(build/'Vtb')], cwd=ROOT, capture_output=True, text=True)
        if q.returncode or b.pass_marker not in q.stdout:
            raise RuntimeError(f'HDL functional failure {mask:#x}:\n{q.stdout[-4000:]}\n{q.stderr[-4000:]}')
        formal = check_equivalence(rtl, b)
        if not formal['formal_ok']:
            raise RuntimeError(f'HDL formal failure {mask:#x}:\n{formal.get("formal_output", "")[-4000:]}')
        print(f'HDL {i}/8 mask=0x{mask:04x}: simulator+formal PASS',flush=True)


def require_valid(row, mask, proto):
    if not all(row.get(k) is True for k in ('functional','formal_ok','synthesis_ok','place_route_ok')):
        raise RuntimeError(f'Invalid physical evaluation: {mask:#x}')
    if row.get('cache_hit') is not False:
        raise RuntimeError(f'Pilot requires fresh, uncached evaluations: {mask:#x}')
    if row.get('pilot_protocol_sha256') != sha(PROTOCOL):
        raise RuntimeError(f'Pilot protocol changed: {mask:#x}')
    if row['fingerprint']['rtl_sha256'] != sha(ROOT/f'rtl/generated/{NAME}_arch_seed_v1/mask_{mask:04x}.v'):
        raise RuntimeError(f'RTL fingerprint mismatch: {mask:#x}')
    if row['fingerprint']['or_image_id'] != proto['eda']['required_orfs_image_id'] or \
       row['fingerprint']['orfs_git_commit'] != proto['eda']['required_orfs_commit']:
        raise RuntimeError('ORFS image differs from preregistration; retain result, stop')
    if abs(row['proxy_reward_v0'] - (-0.001*row['area']+10*row['wns'])) > 1e-5:
        raise RuntimeError('Reward formula drift')
    assert row['boundary_mask'] == mask


def baseline():
    p = verify()
    require_tagged_preregistration()
    if BASELINE.exists():
        raise RuntimeError('Existing baseline, refusing re-evaluation/overwrite')
    result = evaluate(ROOT/f'rtl/{NAME}/baseline.v',benchmark=benchmark(),cache=False,clean=True)
    result['pilot_protocol_sha256'] = sha(PROTOCOL)
    save(BASELINE,result)
    require_valid({**result, 'boundary_mask':0,
                   'fingerprint': {**result['fingerprint'], 'rtl_sha256': result['fingerprint']['rtl_sha256']}}, 0, p)
    print(f'BASELINE PASS: area={result["area"]} WNS={result["wns"]} reward={result["proxy_reward_v0"]}')


def load_rows():
    rows = json.loads(RESULTS.read_text()) if RESULTS.exists() else []
    assert len(rows) <= 8
    assert [int(x['boundary_mask']) for x in rows] == list(PILOT_MASKS[:len(rows)])
    return rows


def validate_rows(p, rows):
    for mask, row in zip(PILOT_MASKS, rows):
        require_valid(row,mask,p)
    if rows:
        base_fp = rows[0]['fingerprint']
        for row in rows[1:]:
            assert all(row['fingerprint'][key] == base_fp[key] for key in FP_FIELDS), 'PPA fingerprint inconsistent'
        assert all(row['fingerprint']['testbench_sha256']==sha(ROOT/f'sim/tb_{NAME}.sv') and
                   row['fingerprint']['reference_rtl_sha256']==sha(ROOT/f'rtl/reference/{NAME}_ref.v') and
                   row['fingerprint']['orfs_config_sha256']==sha(ROOT/f'orfs/{NAME}/config.mk') and
                   row['fingerprint']['sdc_sha256']==sha(ROOT/f'orfs/{NAME}/constraint.sdc') for row in rows)
    if BASELINE.exists():
        base = json.loads(BASELINE.read_text())
        assert base['pilot_protocol_sha256']==sha(PROTOCOL)
        assert is_valid_result(base) and base['cache_hit'] is False
        if rows:
            assert all(base['fingerprint'][key]==rows[0]['fingerprint'][key] for key in FP_FIELDS)
            assert base['fingerprint']['rtl_sha256']==rows[0]['fingerprint']['rtl_sha256']
            assert base['area']==rows[0]['area'] and base['wns']==rows[0]['wns'], 'Zero-mask must reproduce baseline'


def compute_summary(p, rows):
    g = p['gate']
    distinct_pairs = {(round(r['area'], g['area_pair_round_dp']), round(r['wns'], g['wns_pair_round_dp'])) for r in rows}
    distinct_areas = {round(r['area'], g['area_distinct_round_dp']) for r in rows}
    areas = [r['area'] for r in rows]
    rewards = [r['proxy_reward_v0'] for r in rows]
    span = (max(areas)-min(areas))/min(areas)
    rewspan = max(rewards)-min(rewards)
    passed = (len(rows)==8 and len(distinct_pairs)>=g['minimum_distinct_physical_pairs'] and
              len(distinct_areas)>=g['minimum_distinct_areas'] and
              span>=g['minimum_relative_area_span'] and rewspan>=g['minimum_reward_span'])
    front = pareto_front(rows)
    best = sorted(rows, key=lambda r:(-r['proxy_reward_v0'],r['area'],r['boundary_mask']))[0]
    summary = {'experiment':'lanesum16x8_architecture_pilot_v1','pilot_protocol_sha256':sha(PROTOCOL),
               'results_sha256':sha(RESULTS),'gate_passed':passed,'count':len(rows),
               'distinct_physical_pairs':len(distinct_pairs),'distinct_areas':len(distinct_areas),
               'relative_area_span':span,'reward_span':rewspan,
               'best_mask':f'0x{best["boundary_mask"]:04x}', 'best_reward':best['proxy_reward_v0'],
               'frontier_count':len(front)}
    return summary, front


def report(*, save_report=False) -> bool:
    p = verify()
    require_tagged_preregistration()
    rows = load_rows()
    if len(rows) != 8:
        raise RuntimeError(f'Incomplete pilot: {len(rows)}/8')
    validate_rows(p,rows)
    summary, front = compute_summary(p, rows)
    if save_report:
        if SUMMARY.exists() or FRONTIER.exists():
            raise RuntimeError('Partial report files already present; preserve and investigate')
        save(FRONTIER,front)
        save(SUMMARY,summary)
    else:
        assert SUMMARY.exists() and FRONTIER.exists(), 'Report files missing'
        assert json.loads(SUMMARY.read_text()) == summary
        assert json.loads(FRONTIER.read_text()) == front
    print(f'GATE={"PASS" if summary["gate_passed"] else "FAIL"} '
          f'signatures={summary["distinct_physical_pairs"]} areas={summary["distinct_areas"]} '
          f'area_span={100*summary["relative_area_span"]:.2f}% '
          f'reward_span={summary["reward_span"]:.6f} frontier={summary["frontier_count"]} '
          f'best={summary["best_mask"]} score={summary["best_reward"]:.6f}',flush=True)
    return summary['gate_passed']


def seeds():
    p = verify()
    require_tagged_preregistration()
    if not BASELINE.exists():
        raise RuntimeError('Physical baseline missing; run baseline stage first')
    rows = load_rows()
    validate_rows(p,rows)
    if SUMMARY.exists() or FRONTIER.exists():
        if len(rows) != 8:
            raise RuntimeError('Report exists but pilot incomplete')
        if not report():
            raise RuntimeError('Diversity gate failed: STOP')
        return
    for i, mask in enumerate(PILOT_MASKS[len(rows):],start=len(rows)+1):
        rtl = ROOT/f'rtl/generated/{NAME}_arch_seed_v1/mask_{mask:04x}.v'
        row = evaluate(rtl,benchmark=benchmark(),cache=False,clean=True)
        row.update(boundary_mask=mask,mask=f'0x{mask:04x}',pilot_protocol_sha256=sha(PROTOCOL))
        rows.append(row)
        save(RESULTS,rows)  # preserve even failed measurements
        require_valid(row,mask,p)
        validate_rows(p,rows)
        print(f'SEED {i}/8 {mask:#06x}: area={row["area"]:.3f} WNS={row["wns"]:.5f} '
              f'reward={row["proxy_reward_v0"]:.6f}',flush=True)
    if not report(save_report=True):
        raise RuntimeError('Diversity gate FAILED. Do not run search or revise this gate after seeing results.')


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('stage', choices=('scaffold','verify','hdl','baseline','seeds','report'))
    a=parser.parse_args()
    if a.stage=='scaffold': scaffold()
    elif a.stage=='verify': verify()
    elif a.stage=='hdl': hdl()
    elif a.stage=='baseline': baseline()
    elif a.stage=='seeds': seeds()
    elif a.stage=='report':
        if not report():
            raise SystemExit(2)


if __name__=='__main__': main()
