"""Preregister and test fresh popcount-tree widths without altering frozen code.

Stages: scaffold -> verify -> hdl -> baseline [--width W] -> seeds [--width W]
-> report [--width W]. Run no physical EDA before committing scaffold/protocol.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
from pathlib import Path

from chiprl.benchmarks import ROOT
from chiprl.popcount_tree_widths_v1 import (
    FRESH_WIDTHS, benchmark, config, mask_digits, name, pilot_masks,
    reference, render, sdc, testbench,
)

PROTOCOL = ROOT / "experiments/protocol_popcount_tree_freshwidth_pilot_v1.json"
SOURCE_FILES = (
    "chiprl/popcount_tree_widths_v1.py",
    "experiments/popcount_tree_freshwidth_pilot_v1.py",
    "chiprl/evaluate.py",
    "chiprl/benchmarks.py",
    "chiprl/formal.py",
    "chiprl/popcount_tree_generator.py",
)
FINGERPRINT_FIELDS = (
    "schema_version", "benchmark", "top_module", "testbench_sha256",
    "reference_rtl_sha256", "orfs_config_sha256", "sdc_sha256",
    "formal_seq", "or_image_id", "orfs_git_commit", "verilator",
)
GATE = {
    "all_eight_functional_formal_routed_uncached": True,
    "minimum_distinct_rounded_physical_pairs": 4,
    "area_round_dp": 2,
    "wns_round_dp": 3,
    "minimum_distinct_rounded_areas": 3,
    "area_distinct_round_dp": 1,
    "minimum_relative_area_span": 0.01,
    "minimum_reward_span": 0.10,
}


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def save_atomic(path: Path, payload) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")
    tmp.replace(path)


def create_once(path: Path, data: str) -> None:
    if path.exists():
        if path.read_text() != data:
            raise RuntimeError(f"Existing file differs. STOP without overwrite: {path}")
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(data)
    print("CREATE", path.relative_to(ROOT))


def files_for(width: int) -> dict[str, str]:
    nm = name(width)
    pathprefix = f"rtl/generated/{nm}_arch_seed_v1"
    files = {
        f"rtl/reference/{nm}_ref.v": reference(width),
        f"sim/tb_{nm}.sv": testbench(width),
        f"orfs/{nm}/config.mk": config(width),
        f"orfs/{nm}/constraint.sdc": sdc(width),
        f"rtl/{nm}/baseline.v": render(width, 0),
    }
    for mask in pilot_masks(width):
        filename = f"mask_{mask:0{mask_digits(width)}x}.v"
        files[f"{pathprefix}/{filename}"] = render(width, mask)
    return files


def scaffold() -> None:
    if PROTOCOL.exists():
        raise RuntimeError(f"Protocol already exists: verify rather than overwrite: {PROTOCOL}")
    # Historical scripts enforce old source hashes. These files MUST NOT be edited.
    prior = ROOT / "experiments/protocol_popcount_tree_v3_v1.json"
    frozen = json.loads(prior.read_text())["source_sha256"]
    for rel in ("chiprl/benchmarks.py", "chiprl/evaluate.py", "chiprl/popcount_tree_generator.py"):
        if sha(ROOT / rel) != frozen[rel]:
            raise RuntimeError(f"Historical frozen source differs from v3 protocol: {rel}")
    generated = {}
    for width in FRESH_WIDTHS:
        generated.update(files_for(width))
    for rel, body in generated.items():
        create_once(ROOT / rel, body)
    protocol = {
        "experiment": "popcount_tree_freshwidth_diversity_v1",
        "status": "PREREGISTER_BEFORE_NEW_WIDTH_PPA",
        "fresh_widths": list(FRESH_WIDTHS),
        "relationship_to_32bit": "Width transfer within same task family; 32-bit data excluded from new measurements",
        "node_order": "bottom-up, left-to-right",
        "action_grammar": "width-1 independent decisions: arithmetic addition (0) or explicit CLA (1)",
        "reference": "one-cycle unsigned popcount(a_i), reset and invalid-cycle output hold; b_i ignored",
        "shared_pilot_masks": {
            name(w): [f"0x{x:0{mask_digits(w)}x}" for x in pilot_masks(w)]
            for w in FRESH_WIDTHS
        },
        "rtl_hashes": {rel: hashlib.sha256(body.encode()).hexdigest()
                       for rel, body in sorted(generated.items())},
        "source_sha256": {rel: sha(ROOT / rel) for rel in SOURCE_FILES},
        "eda": {
            "platform": "Nangate45", "clock_period_ns": 10.0,
            "die_and_core": {"popcount16_tree": "80x80 die, [5,5,75,75] core",
                             "popcount64_tree": "150x150 die, [5,5,145,145] core"},
            "place_density": 0.2, "fixed_reward": "-0.001 * area + 10 * WNS",
            "cache": False, "clean": True,
        },
        "gate": GATE,
        "gate_application": "each width individually; failure is preserved, no threshold relaxation",
        "anticipated_future_methods_not_yet_executed": [
            "corrected v3 global", "uniform local one-flip", "50/50 global-local with v3 updates only on global proposals",
            "50/50 frozen global-local with no policy updates",
        ],
        "future_study_scope": "freeze implemented learning protocols before seeing new-width search results; never reuse 32-bit one-flip data as held-out",
        "stop_after": "new baseline physical validations, followed by separate eight-architecture diversity gates",
    }
    save_atomic(PROTOCOL, protocol)
    print("PASS: two fresh widths and fixed eight-mask diversity pilots preregistered (no EDA)")


def verify():
    proto = json.loads(PROTOCOL.read_text())
    assert proto["fresh_widths"] == list(FRESH_WIDTHS)
    for rel, h in proto["source_sha256"].items():
        assert sha(ROOT / rel) == h, f"source drift: {rel}"
    for rel, h in proto["rtl_hashes"].items():
        assert sha(ROOT / rel) == h, f"RTL/config drift: {rel}"
    from chiprl.popcount_tree_generator import render as old_render, PILOT_MASKS
    from chiprl.popcount_tree_widths_v1 import render as new_render
    for m in PILOT_MASKS:
        assert new_render(32, m) == old_render(m), "32-bit historical generator behavior changed"
    for width in FRESH_WIDTHS:
        assert [int(x, 0) for x in proto["shared_pilot_masks"][name(width)]] == list(pilot_masks(width))
        for mask in pilot_masks(width):
            text = render(width, mask)
            assert text.count("// node ") == width - 1
            assert text.count("// node ") == (width // 2 + width // 4 + width // 8 + width // 16 + (width // 32 if width >= 32 else 0) + (width // 64 if width >= 64 else 0))
            assert text.count("CLA\n") == mask.bit_count()
            assert text.count("ADD\n") == width - 1 - mask.bit_count()
    print("PASS: registered sources/hashes, exact historical 32-bit RTL, 16 new architectural RTL files")
    return proto


def valid(r):
    return all(r.get(k) is True for k in ("functional", "formal_ok", "synthesis_ok", "place_route_ok")) and (
        r.get("area") is not None and r.get("wns") is not None and r.get("proxy_reward_v0") is not None
    )


def test_hdl(width: int):
    verify()
    from chiprl.formal import check_equivalence
    bench = benchmark(width)
    import shutil
    if shutil.which("verilator") is None:
        raise RuntimeError("Verilator missing; run on EDA development machine")
    for idx, mask in enumerate(pilot_masks(width), start=1):
        candidate = ROOT / f"rtl/generated/{name(width)}_arch_seed_v1/mask_{mask:0{mask_digits(width)}x}.v"
        build = ROOT / ".chiprl" / "freshwidth_zeroeda_v1" / name(width) / f"m_{mask:0{mask_digits(width)}x}"
        build.mkdir(parents=True, exist_ok=True)
        p = subprocess.run([
            "verilator", "--binary", "--timing", "-Wall", "-Wno-fatal",
            "--Mdir", str(build), str(candidate), str(bench.testbench), "--top-module", "tb",
        ], cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        if p.returncode:
            print("\n".join(p.stdout.splitlines()[-80:]))
            raise RuntimeError(f"Verilator compilation failed: {name(width)} {mask:#x}")
        r = subprocess.run([str(build / "Vtb")], cwd=ROOT, text=True,
                           stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        if r.returncode or bench.pass_marker not in r.stdout:
            print("\n".join(r.stdout.splitlines()[-80:]))
            raise RuntimeError(f"Verilator protocol failed: {name(width)} {mask:#x}")
        f = check_equivalence(candidate, bench)
        if not f["formal_ok"]:
            print(f["formal_output"][-5000:])
            raise RuntimeError(f"Formal failed: {name(width)} {mask:#x}")
        print(f"{name(width)} {idx}/8 0x{mask:0{mask_digits(width)}x}: simulator + formal PASS")
    print(f"PASS: {name(width)} all eight candidates passed HDL verification; no PPA")


def baseline(width: int):
    verify()
    from chiprl.evaluate import evaluate
    nm = name(width)
    dest = ROOT / "results" / "popcount_freshwidth_baseline_v1" / f"{nm}.json"
    if dest.exists():
        raise RuntimeError(f"Baseline record exists, refusing re-run/overwrite: {dest}")
    candidate = ROOT / "rtl" / nm / "baseline.v"
    result = evaluate(candidate, benchmark=benchmark(width), cache=False, clean=True)
    result["pilot_protocol_sha256"] = sha(PROTOCOL)
    save_atomic(dest, result)
    if not valid(result) or result["cache_hit"]:
        raise RuntimeError(f"Baseline invalid; record preserved: {dest}")
    print(f"BASELINE PASS {nm}: area={result['area']} WNS={result['wns']} reward={result['proxy_reward_v0']}")


def seed_rows(width: int):
    path = ROOT / "results" / f"{name(width)}_arch_seed_v1" / "results.json"
    return path, json.loads(path.read_text()) if path.is_file() else []


def run_seeds(width: int):
    verify()
    nm = name(width)
    baseline_path = ROOT / "results/popcount_freshwidth_baseline_v1" / f"{nm}.json"
    if not baseline_path.exists() or not valid(json.loads(baseline_path.read_text())):
        raise RuntimeError(f"Baseline missing or invalid for {nm}; stop")
    path, rows = seed_rows(width)
    masks = pilot_masks(width)
    assert len(rows) <= 8
    assert [int(r["boundary_mask"]) for r in rows] == list(masks[:len(rows)])
    assert all(r["pilot_protocol_sha256"] == sha(PROTOCOL) for r in rows)
    if len(rows) == 8:
        print(f"{nm}: existing corpus complete, no further EDA")
        report(width)
        return
    from chiprl.evaluate import evaluate
    for idx, m in enumerate(masks[len(rows):], start=len(rows) + 1):
        c = ROOT / f"rtl/generated/{nm}_arch_seed_v1/mask_{m:0{mask_digits(width)}x}.v"
        result = evaluate(c, benchmark=benchmark(width), cache=False, clean=True)
        result.update(boundary_mask=m, mask=f"0x{m:0{mask_digits(width)}x}",
                      pilot_protocol_sha256=sha(PROTOCOL))
        rows.append(result)
        save_atomic(path, rows)
        print(f"{nm} {idx}/8 {result['mask']}: valid={valid(result)} area={result.get('area')} "
              f"WNS={result.get('wns')} reward={result.get('proxy_reward_v0')}", flush=True)
        if not valid(result):
            raise RuntimeError(f"Invalid candidate saved; preserve data and stop {nm} {m:#x}")
    report(width)


def dominates(a, b):
    return a["area"] <= b["area"] and a["wns"] >= b["wns"] and (
        a["area"] < b["area"] or a["wns"] > b["wns"]
    )


def report(width: int):
    verify()
    nm = name(width)
    path, rows = seed_rows(width)
    masks = pilot_masks(width)
    assert len(rows) == len(masks), f"{nm}: only {len(rows)}/8 seeds present"
    assert [int(r["boundary_mask"]) for r in rows] == list(masks)
    assert all(valid(r) and r["cache_hit"] is False and r["pilot_protocol_sha256"] == sha(PROTOCOL) for r in rows)
    bench = benchmark(width)
    fingerprints = {
        "testbench_sha256": sha(bench.testbench),
        "reference_rtl_sha256": sha(bench.reference),
        "orfs_config_sha256": sha(bench.orfs_config_host),
        "sdc_sha256": sha(bench.sdc),
    }
    for r in rows:
        fp = r["fingerprint"]
        assert all(fp[k] == rows[0]["fingerprint"][k] for k in FINGERPRINT_FIELDS)
        for k, v in fingerprints.items():
            assert fp[k] == v, f"fingerprint changed: {k}"
        c = ROOT / f"rtl/generated/{nm}_arch_seed_v1/mask_{int(r['boundary_mask']):0{mask_digits(width)}x}.v"
        assert fp["rtl_sha256"] == sha(c)
        assert abs(r["proxy_reward_v0"] - (-0.001 * r["area"] + 10 * r["wns"])) < 0.00001
    p = json.loads(PROTOCOL.read_text())
    g = p["gate"]
    signatures = {(round(r["area"], g["area_round_dp"]), round(r["wns"], g["wns_round_dp"])) for r in rows}
    areas = {round(r["area"], g["area_distinct_round_dp"]) for r in rows}
    area_span = (max(r["area"] for r in rows) - min(r["area"] for r in rows)) / min(r["area"] for r in rows)
    reward_span = max(r["proxy_reward_v0"] for r in rows) - min(r["proxy_reward_v0"] for r in rows)
    passed = (len(signatures) >= g["minimum_distinct_rounded_physical_pairs"]
              and len(areas) >= g["minimum_distinct_rounded_areas"]
              and area_span >= g["minimum_relative_area_span"]
              and reward_span >= g["minimum_reward_span"])
    frontier = [r for r in rows if not any(dominates(other, r) for other in rows if other is not r)]
    best = max(rows, key=lambda r: r["proxy_reward_v0"])
    print(f"{nm}: gate={'PASS' if passed else 'FAIL'} signatures={len(signatures)} areas={len(areas)} "
          f"area_span={area_span:.2%} reward_span={reward_span:.6f} frontier={len(frontier)} "
          f"best={best['mask']} reward={best['proxy_reward_v0']:.6f}")
    dest = path.parent
    save_atomic(dest / "frontier.json", sorted(frontier, key=lambda r: (r["area"], -r["wns"])))
    save_atomic(dest / "summary.json", {
        "benchmark": nm, "pilot_protocol_sha256": sha(PROTOCOL), "results_sha256": sha(path),
        "eight_valid_uncached": True, "gate_passed": passed,
        "distinct_signatures": len(signatures), "distinct_rounded_areas": len(areas),
        "relative_area_span": area_span, "reward_span": reward_span,
        "frontier_size": len(frontier), "best_mask": best["mask"],
        "best_reward": best["proxy_reward_v0"], "predeclared_gate": g,
    })
    if not passed:
        print("STOP: failed preregistered diversity gate; do NOT launch RL on this width")
    return passed


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("stage", choices=("scaffold", "verify", "hdl", "baseline", "seeds", "report"))
    p.add_argument("--width", type=int, choices=FRESH_WIDTHS)
    args = p.parse_args()
    if args.stage == "scaffold":
        assert args.width is None
        scaffold()
    elif args.stage == "verify":
        verify()
    else:
        if args.width is None:
            raise SystemExit(f"Specify --width, one of {FRESH_WIDTHS}")
        {"hdl": test_hdl, "baseline": baseline, "seeds": run_seeds, "report": report}[args.stage](args.width)


if __name__ == "__main__":
    main()
