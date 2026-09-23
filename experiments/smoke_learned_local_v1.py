"""Zero-EDA tests: lane-sum arithmetic, finite differences, synthetic runs.

No physical measurements, no policy tuning from new-family PPA, no writes.
This may use fake deterministic reward functions ONLY to check source behavior.
"""
from __future__ import annotations

import hashlib
import math
import random

from chiprl.lane_sum_tree_v1 import BITS,PILOT_MASKS,oracle,render,NAME
from chiprl.learned_local_edit_v1 import ConditionalLocalEditPolicy, FEATURE_NAMES
from chiprl.rl_env import is_valid_result
from experiments.learned_local_study_v1 import (
    METHODS,RNG_SEEDS,BUDGET,initial_policies,initial_snapshots,
    propose,learn,replay,
)


def smoke_generator():
    rng=random.Random(1234)
    for a,b,expected in [(0,0,0),((1<<64)-1,(1<<64)-1,4080),
                         (int('01'*8,16),int('02'*8,16),24)]:
        assert oracle(a,b)==expected
    for _ in range(400):
        a=rng.getrandbits(64);b=rng.getrandbits(64)
        expected=sum(((a>>(i*8))&255)+((b>>(i*8))&255) for i in range(8))
        assert oracle(a,b)==expected and 0<=expected<=4080
    texts=[render(x) for x in PILOT_MASKS]
    assert len({hashlib.sha256(x.encode()).digest() for x in texts})==8
    for m,t in zip(PILOT_MASKS,texts):
        assert t.count('// node ')==BITS
        assert t.count('CLA\n')==m.bit_count()
        assert f'module {NAME}' in t
    print('PASS: 400 Python oracle vectors and 8 distinct 15-node RTL designs')


def smoke_gradient():
    rng=random.Random(7331)
    for leaves in (16,64):
        policy=ConditionalLocalEditPolicy(leaves=leaves)
        assert len(policy.nodes)==leaves-1
        mask=rng.getrandbits(leaves-1)
        seen={mask^(1<<j) for j in (0,2,5)}
        eligible=policy.eligible(mask,seen)
        assert set(eligible)==set(range(leaves-1))-{0,2,5}
        policy.theta=[rng.uniform(-0.5,0.5) for _ in FEATURE_NAMES]
        probs=policy.probabilities(mask,eligible)
        assert abs(sum(probs.values())-1)<1e-13
        chosen=eligible[len(eligible)//2]
        analytical=policy.log_grad(mask,chosen,eligible)
        eps=1e-6
        for j,g in enumerate(analytical):
            orig=policy.theta[j]
            policy.theta[j]=orig+eps
            pplus=math.log(policy.probabilities(mask,eligible)[chosen])
            policy.theta[j]=orig-eps
            pminus=math.log(policy.probabilities(mask,eligible)[chosen])
            policy.theta[j]=orig
            fd=(pplus-pminus)/(2*eps)
            assert abs(fd-g)<1e-8, (leaves,j,fd,g)
        # Score-function identity: sum_a p(a) grad log p(a) = 0.
        for j in range(len(FEATURE_NAMES)):
            e=math.fsum(probs[k]*policy.log_grad(mask,k,eligible)[j] for k in eligible)
            assert abs(e)<1e-12, (leaves,j,e)
        singleton=(eligible[0],)
        assert all(abs(g)<1e-15 for g in policy.log_grad(mask,eligible[0],singleton))
        frozen=ConditionalLocalEditPolicy(leaves=leaves)
        pure=frozen.probabilities(mask,eligible)
        assert max(pure.values())-min(pure.values())<1e-15
        print(f'PASS: {leaves-1}-node exact conditional finite-difference gradient / masked support')


def synthetic_seeds():
    # Synthetic values intentionally NOT populated from the real new family.
    return [{'boundary_mask':m,'area':200.0+0.04*i,'wns':7.0+0.01*i,
             'power_w':0.0,'proxy_reward_v0':70.0+0.12*i,
             'functional':True,'formal_ok':True,'synthesis_ok':True,'place_route_ok':True}
            for i,m in enumerate(PILOT_MASKS)]


def synthetic_score(mask):
    # Nonstationary search geometry is not inferred from any EDA records.
    area=180.0+1.7*mask.bit_count()+0.002*(mask%131)
    wns=7.0+0.023*((mask*59)%19)-0.011*mask.bit_count()
    return {'functional':True,'formal_ok':True,'synthesis_ok':True,'place_route_ok':True,
            'area':area,'wns':wns,'power_w':0.0,'proxy_reward_v0':-0.001*area+10.0*wns,
            'cache_hit':False}


def smoke_trajectories():
    seeds=synthetic_seeds()
    divergent_local = divergent_hybrid = False
    for seed in RNG_SEEDS:
        first={}
        sampled={}
        for method in METHODS:
            local,global_policy=initial_policies(seeds)
            initial=initial_snapshots(local,global_policy)
            archive=[dict(r) for r in seeds]
            seen={r['boundary_mask'] for r in seeds}
            records=[]
            for i in range(BUDGET):
                p=propose(method,i,local,global_policy,archive,seen,seed)
                mask=p['mask'];assert mask not in seen
                if i==0:first[method]=mask
                result=synthetic_score(mask)
                rec={'query_index':i,'boundary_mask':mask,'status':'success',
                     'result':result,'proposal_source':p['source'],
                     'parent_mask':p['parent'],'chosen_bit':p['bit'],
                     'parent_score':p['parent_score'],
                     'eligible_bits':list(p['eligible_bits']) if p['eligible_bits'] else None}
                records.append(rec)
                learn(method,p,local,global_policy,result['proxy_reward_v0'],set(seen))
                seen.add(mask)
                archive.append({**result,'boundary_mask':mask})
            sampled[method]=[r['boundary_mask'] for r in records]
            expected=initial_snapshots(local,global_policy)
            duplicate_local,duplicate_global=initial_policies(seeds)
            assert replay(method,seed,duplicate_local,duplicate_global,seeds,records)[0]==seen
            assert initial_snapshots(duplicate_local,duplicate_global)==expected
            assert len(records)==16 and len(seen)==len(seeds)+16
            if method in ('uniform_local','frozen_hybrid'):
                assert local.theta==[0.0]*len(FEATURE_NAMES)
            if method in ('learned_local','learned_hybrid'):
                assert local.updates==(16 if method=='learned_local' else 8)
            if method in ('learned_local','uniform_local','learned_hybrid','frozen_hybrid'):
                assert global_policy.snapshot()==initial['global'], 'hybrid global policy must be FROZEN'
            print('PASS synthetic replay',method,seed,flush=True)
        assert first['learned_local']==first['uniform_local']
        assert first['learned_hybrid']==first['frozen_hybrid']
        assert first['learned_local']==first['learned_hybrid']
        divergent_local |= sampled['learned_local'] != sampled['uniform_local']
        divergent_hybrid |= sampled['learned_hybrid'] != sampled['frozen_hybrid']
    assert divergent_local, 'Synthetic exercise failed to distinguish learning local policy from uniform'
    assert divergent_hybrid, 'Synthetic exercise failed to distinguish learning hybrid from frozen'
    print('PASS: 15 reproducible zero-EDA trajectories, 240 synthetic queries; both learned arms diverge in actions')


def main():
    smoke_generator();smoke_gradient();smoke_trajectories()


if __name__=='__main__':main()
