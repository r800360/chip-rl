"""Read-only method-by-seed audit of the preregistered 240-query study.

This reconstructs all policies and reports paired gains. It writes a separate
summary only after all 15 runs are complete and their saved state validates.
No EDA, no measurements, no policy/source changes.
"""
from __future__ import annotations

import csv
import hashlib
import json
from pathlib import Path

from chiprl.benchmarks import ROOT
from chiprl.rl_env import is_valid_result
from chiprl.lane_sum_tree_v1 import NAME
from experiments.learned_local_study_v1 import (
    METHODS,RNG_SEEDS,BUDGET,PROTOCOL,SEEDS,PILOT,sha,
    initial_policies,initial_snapshots,replay,
)
from experiments.freeze_learned_local_v1 import verify

OUT=ROOT/'results/learned_local_study_v1_audit'


def write_once(path:Path,data:str):
    path.parent.mkdir(parents=True,exist_ok=True)
    if path.exists():
        if path.read_text()!=data:
            raise RuntimeError(f'Existing audit artifact differs; preserve both: {path}')
    else:path.write_text(data)


def audit():
    verify()
    seeds=json.loads(SEEDS.read_text())
    best_seed=max(r['proxy_reward_v0'] for r in seeds)
    seedfp=seeds[0]['fingerprint']
    fpfields=('schema_version','benchmark','top_module','testbench_sha256',
              'reference_rtl_sha256','orfs_config_sha256','sdc_sha256',
              'formal_seq','or_image_id','orfs_git_commit','verilator')
    summaries=[]
    queryrecords=[]
    for method in METHODS:
        for seed in RNG_SEEDS:
            directory=ROOT/f'results/rl_runs/{NAME}/learned_local_study_v1_{method}_seed_{seed}'
            state=json.loads((directory/'state.json').read_text())
            manifest=json.loads((directory/'run_manifest.json').read_text())
            assert manifest['protocol_sha256']==sha(PROTOCOL)
            assert manifest['pilot_protocol_sha256']==sha(PILOT)
            assert manifest['seed_results_sha256']==sha(SEEDS)
            assert manifest['method']==method and manifest['rng_seed']==seed
            assert state['benchmark']==NAME and state['budget']==BUDGET
            records=state['queries']
            assert len(records)==BUDGET
            local,global_policy=initial_policies(seeds)
            assert json.loads((directory/'policy_initial.json').read_text())==initial_snapshots(local,global_policy)
            replay(method,seed,local,global_policy,seeds,records,checkpoint_dir=directory)
            assert json.loads((directory/'policy_after_16.json').read_text())==initial_snapshots(local,global_policy)
            final=json.loads((directory/'summary.json').read_text())
            assert final['local_policy']==local.snapshot()
            assert final['global_policy']==global_policy.snapshot()
            incumbent=best_seed
            first=None
            fresh=cached=valid=0
            for i,r in enumerate(records):
                assert r['query_index']==i
                result=r.get('result')
                if result and is_valid_result(result):
                    valid+=1
                    assert result['synthesis_ok'] is True
                    assert all(result['fingerprint'][k]==seedfp[k] for k in fpfields)
                    mask=int(r['boundary_mask'])
                    rtl=ROOT/f'rtl/rl/{NAME}/learned_local_study_v1_{method}_seed_{seed}/query_{i:03d}_{mask:04x}.v'
                    assert hashlib.sha256(rtl.read_bytes()).hexdigest()==result['fingerprint']['rtl_sha256']
                    assert abs(result['proxy_reward_v0']-(-0.001*result['area']+10*result['wns'])) < 1e-5
                    if result['cache_hit']: cached+=1
                    else:fresh+=1
                    if result['proxy_reward_v0']>incumbent:
                        incumbent=result['proxy_reward_v0']
                        if first is None:first=i+1
                queryrecords.append({'method':method,'seed':seed,'query':i+1,
                                     'source':r['proposal_source'],'mask':int(r['boundary_mask']),
                                     'parent_mask':r['parent_mask'],'chosen_bit':r['chosen_bit'],
                                     'valid':bool(result and is_valid_result(result)),
                                     'cache_hit':result.get('cache_hit') if result else None,
                                     'score':result.get('proxy_reward_v0') if result else None,
                                     'incumbent':incumbent})
            assert abs(final['best_so_far']['proxy_reward_v0']-incumbent)<1e-10
            row={'method':method,'seed':seed,'seed_reward':best_seed,
                 'final_reward':incumbent,'gain':incumbent-best_seed,
                 'first_improvement_query':first if first is not None else BUDGET+1,
                 'valid_queries':valid,'fresh':fresh,'cached':cached,
                 'local_updates':local.updates}
            summaries.append(row)
            print(f'{method:16s} {seed} gain={row["gain"]:+.6f} '
                  f'first={first or "none":>4} valid={valid:02d}/{BUDGET} '
                  f'cached={cached:02d} local_updates={local.updates}',flush=True)
    paired=[]
    for seed in RNG_SEEDS:
        def gain(method):return next(r['gain'] for r in summaries if r['method']==method and r['seed']==seed)
        pair={'seed':seed,'learned_local_minus_uniform':gain('learned_local')-gain('uniform_local'),
              'learned_hybrid_minus_frozen':gain('learned_hybrid')-gain('frozen_hybrid'),
              'global_minus_uniform':gain('v3_global')-gain('uniform_local')}
        paired.append(pair)
        print('PAIRED',pair,flush=True)
    output={'experiment':'lanesum16x8_learned_local_study_v1',
            'protocol_sha256':sha(PROTOCOL),'seed_results_sha256':sha(SEEDS),
            'runs':summaries,'paired':paired,
            'total_queries':len(queryrecords),
            'cache_hits':sum(r['cached'] for r in summaries),
            'fresh_evaluations':sum(r['fresh'] for r in summaries),
            'limitations':'One shared tree topology, one non-popcount task family, three RNG seeds, selected after exploratory popcount studies.'}
    assert len(summaries)==15 and len(queryrecords)==240
    write_once(OUT/'summary.json',json.dumps(output,indent=2,sort_keys=True)+'\n')
    for name,rows in (('runs.csv',summaries),('queries.csv',queryrecords),('paired.csv',paired)):
        import io
        buf=io.StringIO()
        writer=csv.DictWriter(buf,fieldnames=list(rows[0]),lineterminator='\n')
        writer.writeheader();writer.writerows(rows)
        write_once(OUT/name,buf.getvalue())
    print(f'PASS: {len(summaries)} replayed runs; {len(queryrecords)} logical queries; '
          f'fresh={output["fresh_evaluations"]} cache_hits={output["cache_hits"]}')
    print('Summary:',OUT/'summary.json')


if __name__=='__main__':audit()
