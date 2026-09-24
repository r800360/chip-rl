"""Run the frozen lane-sum pilot stages under formal amendment 1.

Identical to `python -m experiments.lanesum_pilot_v1 <stage>` except that
formal equivalence uses the decomposed tree proof (see
experiments/lanesum_amend1_common.py and chiprl/formal_tree_v1.py).
"""
from __future__ import annotations

import argparse

import experiments.lanesum_pilot_v1 as pilot
from experiments.lanesum_amend1_common import tree_formal


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("stage", choices=("verify", "hdl", "baseline", "seeds", "report"))
    stage = parser.parse_args().stage
    with tree_formal(pilot):
        if stage == "verify":
            pilot.verify()
        elif stage == "hdl":
            pilot.hdl()
        elif stage == "baseline":
            pilot.baseline()
        elif stage == "seeds":
            pilot.seeds()
        elif stage == "report" and not pilot.report():
            raise SystemExit(2)


if __name__ == "__main__":
    main()
