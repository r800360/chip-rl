"""Freeze post-gate lane-sum seeds and the prespecified 240-query study.

The pilot preregistration already fingerprints the search policy code before
EDA; this file freezes the *measurements* before any search queries. It never
modifies the earlier pilot protocol or any source files.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
from pathlib import Path

from chiprl.benchmarks import ROOT
from chiprl.rl_env import is_valid_result
from chiprl.lane_sum_tree_v1 import NAME, PILOT_MASKS
from chiprl.learned_local_edit_v1 import FEATURE_NAMES, LEARNING_RATE, REWARD_SCALE, ADVANTAGE_CLIP, PARAMETER_CLIP
from experiments.lanesum_pilot_v1 import (
    PROTOCOL as PILOT, BASELINE, RESULTS, SUMMARY, FRONTIER,
    FP_FIELDS, verify as pilot_verify, report as pilot_report,
)
from experiments.learned_local_study_v1 import METHODS,RNG_SEEDS,BUDGET

FREEZE=ROOT/'experiments/lanesum_seed_freeze_v1.json'
PROTOCOL=ROOT/'experiments/protocol_learned_local_study_v1.json'


def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()


def read(path):return json.loads(path.read_text())


def save_once(path,body):
    if path.exists():raise RuntimeError(f'File already exists, preserve it: {path}')
    path.write_text(json.dumps(body,sort_keys=True,indent=2)+'\n')


def checked_seeds():
    pilot_verify()
    if not pilot_report():
        raise RuntimeError('Diversity pilot failed; stop, do not freeze a search protocol')
    rows=read(RESULTS)
    assert [r['boundary_mask'] for r in rows]==list(PILOT_MASKS)
    assert all(is_valid_result(r) and r['synthesis_ok'] and r['cache_hit'] is False for r in rows)
    p=read(PILOT)
    ref=rows[0]['fingerprint']
    assert all(all(r['fingerprint'][k]==ref[k] for k in FP_FIELDS) for r in rows)
    assert ref['or_image_id']==p['eda']['required_orfs_image_id']
    assert ref['orfs_git_commit']==p['eda']['required_orfs_commit']
    return rows


def planned_protocol(seed_sha,freeze_sha):
    pilot=read(PILOT)
    return {
        'experiment':'lanesum16x8_learned_local_study_v1',
        'stage':'AFTER_EIGHT_PHYSICAL_SEEDS_BEFORE_ANY_SEARCH',
        'pilot_protocol_sha256':sha(PILOT),
        'seed_results_sha256':seed_sha,
        'seed_freeze_sha256':freeze_sha,
        'source_sha256':pilot['source_sha256'],
        'methods':list(METHODS), 'rng_seeds':list(RNG_SEEDS),
        'budget_per_run':BUDGET,
        'total_logical_queries':len(METHODS)*len(RNG_SEEDS)*BUDGET,
        'starting_archive':'Only eight preregistered lane-sum physical seed designs shared; no data from popcount search used as input.',
        'local_parent':'Best own valid archived reward with eligible unseen one-flip neighbors; ties (lower area, lower mask).',
        'local_features':list(FEATURE_NAMES),
        'local_learning_rate':LEARNING_RATE,
        'local_reward_scale':REWARD_SCALE,
        'local_advantage_clip':ADVANTAGE_CLIP,
        'local_theta_clip':PARAMETER_CLIP,
        'local_update':'exact conditional softmax log-gradient over prequery unseen one-bit edits; clipped (candidate_reward-parent_reward)/0.10',
        'frozen_uniform':'zero-initialized feature weights (exact uniform softmax over eligible bits), no local updates',
        'hybrid_schedule':'local at zero-based even query indices; global at odd indices, fixed 8+8',
        'hybrid_global':'same conditioned-v3 policy initialized from lane-sum seeds, no updates in either hybrid',
        'global_only':'v3_global updates corrected conditioned-v3 parameters only after its own global queries',
        'rng_rule':'random.Random(seed*1000 + query_index*4 + (1 for local,2 for global))',
        'invalid_result_rule':'consumes one logical query; local receives clipped negative advantage, global existing failure reward',
        'reward':'frozen -0.001*area + 10*WNS; no fmax-derived reward',
        'primary':[
            'paired learned_local minus uniform_local final incumbent reward gain by RNG seed',
            'paired learned_hybrid minus frozen_hybrid final incumbent reward gain by RNG seed'],
        'secondary':['v3_global minus uniform_local','time to first improvement (17 if censored)',
                     'incumbent reward trajectory AUC','own Pareto improvements',
                     'local policy gradient norm and proposal divergence','fresh/cached evaluations'],
        'scientific_scope':'New arithmetic function (multi-lane sum) but shared tree topology and ADD/CLA grammar; one family and only three paired RNG seeds; exploratory architecture-family transfer, not broad RTL generalization.',
        'stopping':'No retuning or extra trials in response to observed search performance; failed gate or fingerprint stops study.',
    }


def freeze():
    if FREEZE.exists() or PROTOCOL.exists():
        raise RuntimeError('Freeze/protocol already exists; use --verify')
    rows=checked_seeds()
    # Make the git tag an enforceable preregistration boundary.
    try:
        tag=subprocess.check_output(['git','rev-parse','refs/tags/lanesum-pilot-protocol-v1'],cwd=ROOT,text=True,stderr=subprocess.DEVNULL).strip()
    except subprocess.CalledProcessError as ex:
        raise RuntimeError('Commit and tag lanesum-pilot-protocol-v1 BEFORE any physical measurements') from ex
    if list((ROOT/f'results/rl_runs/{NAME}').glob('learned_local_study_v1_*/state.json')):
        raise RuntimeError('Search records already exist: cannot register this study retroactively')
    freeze_doc={
        'experiment':'lanesum16x8_learned_local_study_v1',
        'stage':'EIGHT_SEEDS_FROZEN_BEFORE_SEARCH',
        'pilot_registration_tag':tag,
        'pilot_protocol_sha256':sha(PILOT),
        'seed_results_sha256':sha(RESULTS),
        'seed_summary_sha256':sha(SUMMARY),
        'seed_frontier_sha256':sha(FRONTIER),
        'baseline_sha256':sha(BASELINE),
        'seed_mask_order':[f'0x{x:04x}' for x in PILOT_MASKS],
        'seed_best_reward':max(r['proxy_reward_v0'] for r in rows),
        'seed_best_mask':f'0x{max(rows,key=lambda r:r["proxy_reward_v0"])["boundary_mask"]:04x}',
        'source_sha256':read(PILOT)['source_sha256'],
    }
    save_once(FREEZE,freeze_doc)
    save_once(PROTOCOL,planned_protocol(sha(RESULTS),sha(FREEZE)))
    verify()
    print('FREEZE READY: 5 methods × 3 RNG seeds × 16 physical queries = 240 logical queries')


def verify():
    rows=checked_seeds()
    freeze=read(FREEZE)
    proto=read(PROTOCOL)
    if freeze['pilot_protocol_sha256']!=sha(PILOT) or freeze['seed_results_sha256']!=sha(RESULTS) or \
       freeze['seed_summary_sha256']!=sha(SUMMARY) or freeze['seed_frontier_sha256']!=sha(FRONTIER) or \
       freeze['baseline_sha256']!=sha(BASELINE):
        raise RuntimeError('Frozen physical measurements or pilot protocol changed')
    if freeze['source_sha256']!=read(PILOT)['source_sha256']:
        raise RuntimeError('Previously registered algorithm source changed')
    if proto!=planned_protocol(sha(RESULTS),sha(FREEZE)):
        raise RuntimeError('Search protocol differs from prespecified protocol')
    assert proto['total_logical_queries']==240 and len(rows)==8
    print(f'PASS: pilot gate, seed hashes and frozen search protocol; seed reward={freeze["seed_best_reward"]:.6f}')


def main():
    p=argparse.ArgumentParser(description=__doc__)
    group=p.add_mutually_exclusive_group(required=True)
    group.add_argument('--freeze',action='store_true')
    group.add_argument('--verify',action='store_true')
    a=p.parse_args()
    freeze() if a.freeze else verify()


if __name__=='__main__':main()
