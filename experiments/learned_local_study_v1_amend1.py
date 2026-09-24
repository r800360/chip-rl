"""Run one frozen learned-local trajectory under formal amendment 1.

Identical to `python -m experiments.learned_local_study_v1 --method M --seed S`
except that formal equivalence uses the decomposed tree proof.
"""
from __future__ import annotations

import argparse

import experiments.learned_local_study_v1 as study
from experiments.lanesum_amend1_common import tree_formal


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--method", choices=study.METHODS, required=True)
    parser.add_argument("--seed", type=int, choices=study.RNG_SEEDS, required=True)
    args = parser.parse_args()
    with tree_formal(study):
        study.run(args.method, args.seed)


if __name__ == "__main__":
    main()
