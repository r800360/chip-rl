"""Decomposed formal equivalence for balanced reduction-tree benchmarks.

Problem
-------
chiprl/formal.py proves `candidate == reference` with one Yosys equivalence
run. For lanesum16x8_tree the reference accumulates sixteen 8-bit lanes one at
a time, while candidates reduce them with a balanced tree. The two circuits
share no internal signals, so the SAT problem is a re-association proof over
adder logic. It ran for 70 minutes without finishing, and the same CNF also
defeats MiniSat, Glucose and CaDiCaL for several minutes each.

Method
------
Every proof below uses the same Yosys commands as chiprl/formal.py
(`proc; opt; equiv_make; equiv_simple -seq 4; equiv_induct -seq 4;
equiv_status -assert`). Only the decomposition is new.

1. Per candidate: prove `candidate(mask) == T0`, where T0 is the frozen
   all-ADD tree (mask 0). Tree nodes carry identical names (`n_<level>_<pos>`)
   in both designs, so `equiv_make` turns every node into a cut point and each
   node is proven locally. About 0.5 s instead of more than 70 minutes.

2. Once per benchmark: prove `reference == T0` through a chain of
   intermediate designs. Consecutive designs differ by one local rewrite
   (swap two adjacent operands of the accumulation chain, or rotate
   `(A+B)+C` into `A+(B+C)`). Internal nodes are named by the set of lanes they
   sum (`s_<lane bitmask>`), so every unchanged node is a cut point and each
   step is a three-operand proof. All node widths are exact, so no step relies
   on modular wrap-around.

3. Equivalence is transitive and every design has the same registers
   (`valid_o`, `y_o`), so steps 1 and 2 prove `candidate == reference`.

The certificate from step 2 records the SHA-256 of every intermediate design
and of both endpoints. A candidate proof is accepted only if the certificate's
endpoints match the benchmark's frozen reference and structural reference.
"""
from __future__ import annotations

import hashlib
import json
import os
import subprocess
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from chiprl.benchmarks import ROOT, Benchmark

ORFS = Path.home() / "eda" / "OpenROAD-flow-scripts"
DOCKER_SHELL = ORFS / "flow" / "util" / "docker_shell"
METHOD_ID = "tree_cutpoint_v1"
EQUIV_COMMANDS = (
    "proc",
    "opt",
    "equiv_make {gold} {gate} equiv",
    "hierarchy -top equiv",
    "equiv_simple -seq 4",
    "equiv_induct -seq 4",
    "equiv_status -assert",
)
PROVEN_MARKER = "Equivalence successfully proven!"


# ---------------------------------------------------------------------------
# Benchmark description
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class TreeSpec:
    """What the certificate needs to know about one tree benchmark."""

    name: str
    top_module: str
    lanes: tuple[str, ...]          # Verilog slice for each lane
    lane_width: int
    output_width: int
    reference_order: tuple[int, ...]  # accumulation order used by the reference
    tree_order: tuple[int, ...]       # leaf order of the balanced tree
    structural_reference: Path        # frozen all-ADD tree (mask 0)
    reference: Path                   # frozen behavioral reference


def lanesum16x8_spec() -> TreeSpec:
    lanes = tuple(f"a_i[{8 * i + 7}:{8 * i}]" for i in range(8)) + tuple(
        f"b_i[{8 * i + 7}:{8 * i}]" for i in range(8)
    )
    # Reference: for i in 0..7 { c += a_i[i]; c += b_i[i]; }
    reference_order = tuple(x for i in range(8) for x in (i, 8 + i))
    return TreeSpec(
        name="lanesum16x8_tree",
        top_module="lanesum16x8_tree",
        lanes=lanes,
        lane_width=8,
        output_width=12,
        reference_order=reference_order,
        tree_order=tuple(range(16)),
        structural_reference=ROOT / "rtl/lanesum16x8_tree/baseline.v",
        reference=ROOT / "rtl/reference/lanesum16x8_tree_ref.v",
    )


# ---------------------------------------------------------------------------
# Sum trees: a leaf is an int (lane index); a node is a (left, right) tuple.
# ---------------------------------------------------------------------------

def leaf_mask(tree) -> int:
    if isinstance(tree, int):
        return 1 << tree
    return leaf_mask(tree[0]) | leaf_mask(tree[1])


def exact_width(spec: TreeSpec, tree) -> int:
    count = bin(leaf_mask(tree)).count("1")
    return (((1 << spec.lane_width) - 1) * count).bit_length()


def chain(order) -> Any:
    tree = order[0]
    for leaf in order[1:]:
        tree = (tree, leaf)
    return tree


def balanced(order) -> Any:
    nodes = list(order)
    while len(nodes) > 1:
        nodes = [(nodes[2 * i], nodes[2 * i + 1]) for i in range(len(nodes) // 2)]
    return nodes[0]


def render_tree(spec: TreeSpec, tree, *, comment: str = "") -> str:
    """Verilog with exact-width nodes named by the set of lanes they sum."""
    digits = (len(spec.lanes) + 3) // 4
    lines = []
    if comment:
        lines.append(f"// {comment}")
    lines += [
        f"module {spec.top_module} (",
        "  input wire clk, rst_n, valid_i,",
        "  input wire [63:0] a_i, b_i,",
        "  output reg valid_o,",
        f"  output reg [{spec.output_width - 1}:0] y_o",
        ");",
    ]
    for i, src in enumerate(spec.lanes):
        lines.append(f"wire [{spec.lane_width - 1}:0] lane_{i} = {src};")

    emitted: set[str] = set()

    def emit(node) -> tuple[str, int]:
        if isinstance(node, int):
            return f"lane_{node}", spec.lane_width
        left, lw = emit(node[0])
        right, rw = emit(node[1])
        width = exact_width(spec, node)
        name = f"s_{leaf_mask(node):0{digits}x}"
        if name in emitted:
            raise ValueError(f"duplicate node {name}")
        emitted.add(name)
        lz = f"{{{width - lw}'d0,{left}}}" if lw < width else left
        rz = f"{{{width - rw}'d0,{right}}}" if rw < width else right
        lines.append(f"wire [{width - 1}:0] {name} = {lz} + {rz};")
        return name, width

    root, width = emit(tree)
    if width > spec.output_width:
        raise ValueError("tree root wider than output")
    root_z = (
        f"{{{spec.output_width - width}'d0,{root}}}"
        if width < spec.output_width else root
    )
    lines += [
        "always @(posedge clk) begin",
        "  if (!rst_n) begin",
        "    valid_o <= 1'b0;",
        f"    y_o <= {spec.output_width}'d0;",
        "  end else begin",
        "    valid_o <= valid_i;",
        f"    if (valid_i) y_o <= {root_z};",
        "  end",
        "end",
        "endmodule",
        "",
    ]
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Rewrite schedule: reference chain -> sorted chain -> balanced tree.
# ---------------------------------------------------------------------------

def _get(tree, path):
    for step in path:
        tree = tree[step]
    return tree


def _set(tree, path, value):
    if not path:
        return value
    left, right = tree
    if path[0] == 0:
        return (_set(left, path[1:], value), right)
    return (left, _set(right, path[1:], value))


def _rotate(tree, path):
    """At `path`: ((A + B) + C) -> (A + (B + C))."""
    (a, b), c = _get(tree, path)
    return _set(tree, path, (a, (b, c)))


def rewrite_schedule(spec: TreeSpec) -> list[tuple[str, Any]]:
    """Every tree from chain(reference order) to balanced(tree order).

    Consecutive trees differ by exactly one local rewrite.
    """
    steps: list[tuple[str, Any]] = []
    order = list(spec.reference_order)
    rank = {leaf: i for i, leaf in enumerate(spec.tree_order)}
    steps.append(("reference_order_chain", chain(order)))

    # 1. Bubble sort the accumulation order with adjacent swaps.
    changed = True
    while changed:
        changed = False
        for i in range(len(order) - 1):
            if rank[order[i]] > rank[order[i + 1]]:
                order[i], order[i + 1] = order[i + 1], order[i]
                steps.append((f"swap_{order[i + 1]}_{order[i]}", chain(order)))
                changed = True
    assert order == list(spec.tree_order)

    # 2. Re-associate the chain into a balanced tree with rotations.
    tree = chain(order)

    def convert(path, leaves):
        nonlocal tree
        if len(leaves) <= 2:
            return
        half = len(leaves) // 2
        right_count = len(leaves) - half
        # Subtree at `path` is chain(leaves) = chain(L1) + c0 + c1 + ...
        # Rotate the innermost (chain(L1) + R) + c_j until it is L1 + chain(L2).
        for j in range(1, right_count):
            inner = path + [0] * (right_count - 1 - j)
            tree = _rotate(tree, inner)
            steps.append((f"rotate_{leaf_mask(_get(tree, inner)):04x}", tree))
        convert(path + [0], leaves[:half])
        convert(path + [1], leaves[half:])

    convert([], list(spec.tree_order))
    assert tree == balanced(spec.tree_order), "schedule did not reach balanced tree"
    return steps


# ---------------------------------------------------------------------------
# Yosys execution (inside the frozen ORFS container, like chiprl/formal.py).
# ---------------------------------------------------------------------------

def sha256_file(path: Path) -> str:
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def _container(path: Path) -> str:
    return "/work/" + Path(path).resolve().relative_to(ROOT).as_posix()


def equiv_script(gold: Path, gold_top: str, gate: Path, gate_top: str) -> str:
    """Same proof commands as chiprl/formal.py; renames avoid module clashes."""
    lines = [
        f"read_verilog -formal {_container(gold)}",
        f"rename {gold_top} chiprl_gold",
        f"read_verilog -formal {_container(gate)}",
        f"rename {gate_top} chiprl_gate",
    ]
    lines += [c.format(gold="chiprl_gold", gate="chiprl_gate") for c in EQUIV_COMMANDS]
    return "\n".join(lines) + "\n"


def run_yosys_batch(
    scripts: list[Path],
    *,
    timeout_s: int,
) -> list[dict[str, Any]]:
    """Run several Yosys scripts in one container; one log per script."""
    env = os.environ.copy()
    env.setdefault("OR_IMAGE", "openroad/orfs:local")
    commands = []
    for script in scripts:
        log = script.with_suffix(".log")
        log.unlink(missing_ok=True)
        commands.append(
            f"s=$(date +%s.%N); timeout {timeout_s} yosys -q -s {_container(script)} "
            f"-l {_container(log)} > /dev/null 2>&1; rc=$?; e=$(date +%s.%N); "
            f"echo \"CHIPRL_STEP {script.name} $rc $s $e\""
        )
    proc = subprocess.run(
        [str(DOCKER_SHELL), "bash", "-c", "'" + "; ".join(commands) + "'"],
        cwd=ROOT, env=env, text=True,
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
    )
    timing = {}
    for line in proc.stdout.splitlines():
        if line.startswith("CHIPRL_STEP "):
            _, name, rc, start, end = line.split()
            timing[name] = (int(rc), float(end) - float(start))
    results = []
    for script in scripts:
        log = script.with_suffix(".log")
        text = log.read_text() if log.is_file() else ""
        rc, runtime = timing.get(script.name, (None, None))
        cells = None
        for row in text.splitlines():
            if row.strip().startswith("Of those cells"):
                cells = row.strip()
        results.append({
            "script": script.name,
            "returncode": rc,
            "timed_out": rc in (124, 137),
            "proven": rc == 0 and PROVEN_MARKER in text,
            "equiv_summary": cells,
            "runtime_s": None if runtime is None else round(runtime, 3),
            "log_tail": "\n".join(text.splitlines()[-15:]),
        })
    return results


# ---------------------------------------------------------------------------
# One-time reassociation certificate
# ---------------------------------------------------------------------------

def certificate_dir(spec: TreeSpec) -> Path:
    return ROOT / "rtl" / "formal" / f"{spec.name}_reassociation_v1"


def certificate_path(spec: TreeSpec) -> Path:
    return ROOT / "results" / "formal" / f"{spec.name}_reassociation_certificate_v1.json"


def build_certificate(spec: TreeSpec, *, timeout_s: int = 120) -> dict[str, Any]:
    """Generate intermediate designs, prove every link, save the certificate."""
    out = certificate_dir(spec)
    out.mkdir(parents=True, exist_ok=True)
    work = ROOT / ".chiprl" / "formal_tree" / spec.name
    work.mkdir(parents=True, exist_ok=True)

    schedule = rewrite_schedule(spec)
    designs = []
    for index, (label, tree) in enumerate(schedule):
        path = out / f"step_{index:02d}_{label}.v"
        path.write_text(render_tree(spec, tree, comment=f"step {index}: {label}"))
        designs.append((label, path, spec.top_module))

    chain_links = (
        [("reference", spec.reference, f"{spec.top_module}_ref")]
        + designs
        + [("structural_reference", spec.structural_reference, spec.top_module)]
    )
    scripts = []
    links = []
    for i in range(len(chain_links) - 1):
        (gl, gp, gt), (dl, dp, dt) = chain_links[i], chain_links[i + 1]
        script = work / f"link_{i:02d}.ys"
        script.write_text(equiv_script(gp, gt, dp, dt))
        scripts.append(script)
        links.append({
            "index": i,
            "gold": gp.relative_to(ROOT).as_posix(),
            "gold_sha256": sha256_file(gp),
            "gate": dp.relative_to(ROOT).as_posix(),
            "gate_sha256": sha256_file(dp),
            "rewrite": dl if i else "reference_to_named_chain",
        })

    start = time.perf_counter()
    outcomes = run_yosys_batch(scripts, timeout_s=timeout_s)
    wall = time.perf_counter() - start
    for link, outcome in zip(links, outcomes):
        link.update({k: outcome[k] for k in ("proven", "timed_out", "equiv_summary", "runtime_s")})

    certificate = {
        "method": METHOD_ID,
        "benchmark": spec.name,
        "claim": "reference == structural_reference (sequential equivalence, same Yosys equiv flow)",
        "reference": spec.reference.relative_to(ROOT).as_posix(),
        "reference_sha256": sha256_file(spec.reference),
        "structural_reference": spec.structural_reference.relative_to(ROOT).as_posix(),
        "structural_reference_sha256": sha256_file(spec.structural_reference),
        "equiv_commands": list(EQUIV_COMMANDS),
        "yosys_image": os.environ.get("OR_IMAGE", "openroad/orfs:local"),
        "links": links,
        "link_count": len(links),
        "all_links_proven": all(l["proven"] for l in links),
        "total_wall_s": round(wall, 3),
    }
    path = certificate_path(spec)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(certificate, indent=2, sort_keys=True) + "\n")
    return certificate


def verify_certificate(spec: TreeSpec) -> dict[str, Any]:
    """Hash-check a saved certificate against the frozen endpoints."""
    path = certificate_path(spec)
    if not path.is_file():
        raise FileNotFoundError(f"missing certificate: {path}")
    cert = json.loads(path.read_text())
    problems = []
    if cert.get("method") != METHOD_ID:
        problems.append("method")
    if not cert.get("all_links_proven"):
        problems.append("unproven link")
    if cert["reference_sha256"] != sha256_file(spec.reference):
        problems.append("reference changed")
    if cert["structural_reference_sha256"] != sha256_file(spec.structural_reference):
        problems.append("structural reference changed")
    links = cert["links"]
    if links[0]["gold_sha256"] != cert["reference_sha256"]:
        problems.append("chain does not start at reference")
    if links[-1]["gate_sha256"] != cert["structural_reference_sha256"]:
        problems.append("chain does not end at structural reference")
    for a, b in zip(links, links[1:]):
        if a["gate_sha256"] != b["gold_sha256"]:
            problems.append(f"broken chain at link {b['index']}")
    for link in links:
        if not link["proven"]:
            problems.append(f"link {link['index']} unproven")
        file = ROOT / link["gate"]
        if not file.is_file() or sha256_file(file) != link["gate_sha256"]:
            problems.append(f"design changed: {link['gate']}")
    if problems:
        raise RuntimeError("certificate invalid: " + "; ".join(problems))
    return cert


# ---------------------------------------------------------------------------
# Per-candidate check (drop-in replacement for chiprl.formal.check_equivalence)
# ---------------------------------------------------------------------------

def check_equivalence_tree(
    candidate: str | Path,
    benchmark: Benchmark,
    *,
    spec: TreeSpec | None = None,
    timeout_s: int = 600,
) -> dict[str, Any]:
    spec = spec or lanesum16x8_spec()
    if benchmark.name != spec.name:
        raise ValueError(f"tree checker configured for {spec.name}, got {benchmark.name}")
    if benchmark.reference.resolve() != spec.reference.resolve():
        raise ValueError("benchmark reference differs from certificate reference")

    start = time.perf_counter()
    cert = verify_certificate(spec)

    candidate = Path(candidate)
    if not candidate.is_absolute():
        candidate = ROOT / candidate
    candidate = candidate.resolve()

    digest = hashlib.sha256(
        candidate.read_bytes()
        + spec.structural_reference.read_bytes()
        + METHOD_ID.encode()
    ).hexdigest()[:16]
    work = ROOT / ".chiprl" / "formal_tree" / spec.name / "candidates"
    work.mkdir(parents=True, exist_ok=True)
    script = work / f"{digest}.ys"
    script.write_text(equiv_script(
        spec.structural_reference, spec.top_module, candidate, benchmark.top_module,
    ))
    outcome = run_yosys_batch([script], timeout_s=timeout_s)[0]
    return {
        "formal_ok": bool(outcome["proven"]),
        "formal_runtime_s": round(time.perf_counter() - start, 3),
        "formal_returncode": outcome["returncode"],
        "formal_output": outcome["log_tail"],
        "formal_method": METHOD_ID,
        "formal_timed_out": outcome["timed_out"],
        "formal_certificate_links": cert["link_count"],
    }
