"""Frozen new-family five-arm study: does local-edit policy learning add value?

The 16/32/64-bit popcount search results are NOT used to initialize parameters.
The five methods share only eight preregistered lane-sum physical seed results.
Each method maintains a separate result archive and exact replayable policy.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import random
import subprocess
from pathlib import Path

from chiprl.benchmarks import ROOT
from chiprl.evaluate import evaluate
from chiprl.rl_env import StructuralMaskEnv, is_valid_result
from chiprl.lane_sum_tree_v1 import NAME, BITS, benchmark, write_candidate
from chiprl.learned_local_edit_v1 import ConditionalLocalEditPolicy
from chiprl.conditioned_autoregressive_policy import ConditionedHierarchicalMaskPolicy

METHODS = ('v3_global', 'uniform_local', 'learned_local', 'frozen_hybrid', 'learned_hybrid')
RNG_SEEDS = (33001,33002,33003)
BUDGET = 16
PILOT = ROOT / 'experiments/protocol_lanesum_pilot_v1.json'
FREEZE = ROOT / 'experiments/lanesum_seed_freeze_v1.json'
PROTOCOL = ROOT / 'experiments/protocol_learned_local_study_v1.json'
SEEDS = ROOT / 'results/lanesum16x8_arch_seed_v1/results.json'


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def save(path:Path, obj):
    path.parent.mkdir(parents=True,exist_ok=True)
    tmp=path.with_suffix(path.suffix+'.tmp')
    tmp.write_text(json.dumps(obj,sort_keys=True,indent=2)+'\n')
    tmp.replace(path)


def check_inputs():
    from experiments.freeze_learned_local_v1 import verify
    verify()
    tag='refs/tags/lanesum-learned-local-search-ready-v1'
    for rel in ('experiments/protocol_learned_local_study_v1.json',
                'experiments/lanesum_seed_freeze_v1.json'):
        try:
            data=subprocess.check_output(['git','show',f'{tag}:{rel}'],
                                         cwd=ROOT,stderr=subprocess.DEVNULL)
        except subprocess.CalledProcessError as ex:
            raise RuntimeError('STOP: commit/tag the search protocol and frozen seeds first') from ex
        if hashlib.sha256(data).hexdigest()!=sha(ROOT/rel):
            raise RuntimeError(f'Search-ready tag differs from frozen input: {rel}')
    return json.loads(SEEDS.read_text())


def initial_policies(seed_rows):
    return (ConditionalLocalEditPolicy(leaves=16),
            ConditionedHierarchicalMaskPolicy(bits=BITS, seed_rows=seed_rows))


def initial_snapshots(local,global_policy):
    return {'local':local.snapshot(),'global':global_policy.snapshot()}


def action_source(method:str,index:int) -> str:
    if method=='v3_global':return 'global'
    if method in ('uniform_local','learned_local'):return 'local'
    if method in ('frozen_hybrid','learned_hybrid'):
        return 'local' if index%2==0 else 'global'
    raise ValueError(method)


def rng_for(seed:int,index:int,source:str):
    channel={'local':1,'global':2}[source]
    return random.Random(seed*1000+index*4+channel)


def eligible_parent(archive, seen, local:ConditionalLocalEditPolicy):
    # Fixed deterministic parent choice independent of edit policy.
    ranked=sorted((r for r in archive if is_valid_result(r)),
                  key=lambda r:(-float(r['proxy_reward_v0']),float(r['area']),int(r['boundary_mask'])))
    for parent in ranked:
        mask=int(parent['boundary_mask'])
        eligible=local.eligible(mask,seen)
        if eligible:
            return mask,float(parent['proxy_reward_v0']),eligible
    raise RuntimeError('All one-bit neighbors of all own archived designs exhausted')


def propose(method,index,local,global_policy,archive,seen,seed):
    source=action_source(method,index)
    rng=rng_for(seed,index,source)
    if source=='global':
        mask=global_policy.sample(rng=rng,seen_masks=seen)
        return {'mask':mask,'source':'global','parent':None,'bit':None,
                'parent_score':None,'eligible_bits':None}
    parent,score,eligible=eligible_parent(archive,seen,local)
    bit=local.sample(parent,eligible,rng)
    mask=parent^(1<<bit)
    assert mask not in seen
    return {'mask':mask,'source':'local','parent':parent,'bit':bit,
            'parent_score':score,'eligible_bits':eligible}


def score_of(record):
    r=record.get('result')
    return float(r['proxy_reward_v0']) if r and is_valid_result(r) else -1000.0


def learn(method, proposed, local, global_policy, score, pre_seen):
    if proposed['source']=='local' and method in ('learned_local','learned_hybrid'):
        return local.update(parent=proposed['parent'],chosen_bit=proposed['bit'],
                            eligible_bits=proposed['eligible_bits'], score=score,
                            parent_score=proposed['parent_score'])
    if proposed['source']=='global' and method=='v3_global':
        return global_policy.update_conditioned(mask=proposed['mask'],score=score,
                                                 seen_masks=pre_seen)
    return None


def replay(method,seed,local,global_policy,seed_rows,queries,*,check_actions=True,
           checkpoint_dir=None):
    archive=[dict(r) for r in seed_rows]
    seen={int(r['boundary_mask']) for r in seed_rows}
    for i,record in enumerate(queries):
        if record['query_index']!=i or record['status']=='evaluator_exception':
            raise RuntimeError('Invalid prior query state; preserve it and stop')
        predicted=propose(method,i,local,global_policy,archive,seen,seed)
        mask=int(record['boundary_mask'])
        if check_actions and mask!=predicted['mask']:
            raise RuntimeError(f'Replay action mismatch q={i} {predicted["mask"]:#x}!={mask:#x}')
        if record.get('proposal_source',predicted['source'])!=predicted['source'] or \
           record.get('parent_mask',predicted['parent'])!=predicted['parent'] or \
           record.get('chosen_bit',predicted['bit'])!=predicted['bit']:
            raise RuntimeError(f'Replay action metadata mismatch q={i}')
        # Local eligibility is reconstructed from the prequery OWN seen set.
        if 'eligible_bits' in record and record['eligible_bits'] != (list(predicted['eligible_bits']) if predicted['eligible_bits'] else None):
            raise RuntimeError(f'Eligible local set changed q={i}')
        learn(method,predicted,local,global_policy,score_of(record),set(seen))
        seen.add(mask)
        if record.get('result') and is_valid_result(record['result']):
            archive.append({**record['result'],'boundary_mask':mask})
        if checkpoint_dir is not None:
            checkpoint=checkpoint_dir/f'policy_after_{i+1:02d}.json'
            if checkpoint.is_file() and json.loads(checkpoint.read_text())!=initial_snapshots(local,global_policy):
                raise RuntimeError(f'Saved policy snapshot differs from replay after q={i+1}')
    return seen,archive


def run(method:str,seed:int):
    if method not in METHODS or seed not in RNG_SEEDS:raise ValueError('Unregistered method/seed')
    seeds=check_inputs()
    env=StructuralMaskEnv(
        benchmark=NAME,width=16,
        run_id=f'learned_local_study_v1_{method}_seed_{seed}',
        budget=BUDGET,seed_rows=seeds,
        render_candidate=lambda mask,path:write_candidate(mask,path),
        evaluate_candidate=lambda mask,path:evaluate(path,benchmark=benchmark(),cache=True,clean=False),
    )
    meta={'experiment':'learned_local_study_v1','method':method,'rng_seed':seed,
          'protocol_sha256':sha(PROTOCOL),'pilot_protocol_sha256':sha(PILOT),
          'seed_results_sha256':sha(SEEDS)}
    manifest=env.run_dir/'run_manifest.json'
    if manifest.exists():
        if json.loads(manifest.read_text())!=meta:
            raise RuntimeError('Existing run manifest mismatch; preserve original run')
    elif env.queries_used:
        raise RuntimeError('Saved queries exist without a run manifest; preserve run')
    else:save(manifest,meta)
    local,global_policy=initial_policies(seeds)
    initfile=env.run_dir/'policy_initial.json'
    if initfile.exists():
        if json.loads(initfile.read_text())!=initial_snapshots(local,global_policy):
            raise RuntimeError('Initial policy snapshot changed')
    else:save(initfile,initial_snapshots(local,global_policy))
    seen,archive=replay(method,seed,local,global_policy,seeds,env.state['queries'],
                        checkpoint_dir=env.run_dir)
    if seen!=env.seen_masks():raise RuntimeError('Run seen set differs from policy replay')
    while not env.done:
        i=env.queries_used
        pre_seen=set(seen)
        p=propose(method,i,local,global_policy,archive,seen,seed)
        obs,_,_,_=env.step(p['mask'])
        record=env.state['queries'][-1]
        record.update(proposal_source=p['source'],parent_mask=p['parent'],
                      chosen_bit=p['bit'],parent_score=p['parent_score'],
                      eligible_bits=list(p['eligible_bits']) if p['eligible_bits'] else None)
        env._save()
        if record['status']=='evaluator_exception':
            raise RuntimeError(f'EDA exception at query {i+1}; saved record preserved')
        learn(method,p,local,global_policy,score_of(record),pre_seen)
        seen.add(p['mask'])
        if record.get('result') and is_valid_result(record['result']):
            archive.append({**record['result'],'boundary_mask':p['mask']})
        save(env.run_dir/f'policy_after_{i+1:02d}.json',initial_snapshots(local,global_policy))
        print(f'{NAME} {method} seed={seed} q={i+1:02d}/{BUDGET} '
              f'source={p["source"]} mask={p["mask"]:#06x} '
              f'parent={p["parent"] if p["parent"] is None else hex(p["parent"])} '
              f'status={record["status"]} score={score_of(record):.6f} '
              f'best={obs["best_so_far"]["proxy_reward_v0"]:.6f}',flush=True)
    save(env.run_dir/'summary.json',{
        **meta,'queries':BUDGET,
        'seed_best_reward':max(row['proxy_reward_v0'] for row in seeds),
        'best_so_far':env.observation()['best_so_far'],
        'local_policy':local.snapshot(),'global_policy':global_policy.snapshot(),
        'local_queries':sum(x['proposal_source']=='local' for x in env.state['queries']),
        'global_queries':sum(x['proposal_source']=='global' for x in env.state['queries']),
    })
    print(f'COMPLETE {NAME} {method} seed={seed}',flush=True)


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--method',choices=METHODS,required=True)
    p.add_argument('--seed',type=int,choices=RNG_SEEDS,required=True)
    args=p.parse_args();run(args.method,args.seed)


if __name__=='__main__':main()
