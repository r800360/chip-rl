import json
from pathlib import Path

from chiprl.evaluate import evaluate


ROOT = Path(__file__).resolve().parents[1]

CANDIDATES = sorted(
    (ROOT / "rtl" / "candidates").glob("candidate_*.v")
)


def fmt(value, digits=3):
    if value is None:
        return "-"

    if isinstance(value, float):
        return f"{value:.{digits}f}"

    return str(value)


def main():
    results = []

    for candidate in CANDIDATES:
        rel = candidate.relative_to(ROOT)

        print(f"\n=== Evaluating {rel} ===")

        result = evaluate(rel)
        results.append(result)

    out = ROOT / "results" / "candidate_comparison.json"

    out.write_text(
        json.dumps(results, indent=2) + "\n"
    )

    print()
    print(
        f"{'candidate':<15}"
        f"{'func':>7}"
        f"{'route':>8}"
        f"{'cells':>9}"
        f"{'area':>12}"
        f"{'WNS':>10}"
        f"{'TNS':>10}"
        f"{'wire':>12}"
        f"{'DRC':>7}"
        f"{'runtime':>11}"
        f"{'reward':>12}"
    )

    print("-" * 113)

    for r in results:
        print(
            f"{Path(r['candidate']).stem:<15}"
            f"{str(r['functional']):>7}"
            f"{str(r['place_route_ok']):>8}"
            f"{fmt(r['cells'], 0):>9}"
            f"{fmt(r['area']):>12}"
            f"{fmt(r['wns']):>10}"
            f"{fmt(r['tns']):>10}"
            f"{fmt(r['wirelength']):>12}"
            f"{fmt(r['drc_errors'], 0):>7}"
            f"{fmt(r['runtime_s']):>11}"
            f"{fmt(r['reward']):>12}"
        )

    print(f"\nSaved: {out}")


if __name__ == "__main__":
    main()
