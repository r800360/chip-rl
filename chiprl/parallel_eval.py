"""Run the frozen evaluator on many designs at once.

Each worker process calls chiprl.evaluate.evaluate unchanged. Two workers
never touch the same design at the same time: evaluations of identical RTL
share an ORFS run directory, so a per-design file lock serializes them.
"""
from __future__ import annotations

import fcntl
import hashlib
import time
from concurrent.futures import ProcessPoolExecutor
from contextlib import contextmanager
from pathlib import Path

from chiprl.benchmarks import ROOT

LOCKS = ROOT / ".chiprl" / "locks"


@contextmanager
def design_lock(benchmark: str, candidate: Path):
    LOCKS.mkdir(parents=True, exist_ok=True)
    digest = hashlib.sha256(Path(candidate).read_bytes()).hexdigest()[:16]
    with open(LOCKS / f"{benchmark}_{digest}.lock", "w") as handle:
        fcntl.flock(handle, fcntl.LOCK_EX)
        try:
            yield
        finally:
            fcntl.flock(handle, fcntl.LOCK_UN)


def _run(job: tuple[str, str, bool, bool]) -> dict:
    import contextlib
    import io
    import types

    from chiprl.evaluate import evaluate
    from chiprl.benchmarks import BENCHMARKS

    candidate, bench_name, cache, clean = job
    runner = types.SimpleNamespace(evaluate=evaluate)
    formal_context = contextlib.nullcontext()
    if bench_name in BENCHMARKS:
        benchmark = bench_name
    elif bench_name == "lanesum16x8_tree":
        # Lane-sum designs need the decomposed tree proof (formal amendment 1);
        # the monolithic checker does not finish on this benchmark.
        from chiprl.lane_sum_tree_v1 import benchmark as lanesum_benchmark
        from experiments.lanesum_amend1_common import tree_formal
        benchmark = lanesum_benchmark()
        formal_context = tree_formal(runner)  # also tags each record with the proof method
    else:  # popcount tree widths created outside the registry
        from chiprl.popcount_tree_widths_v1 import benchmark as width_benchmark
        benchmark = width_benchmark(int(bench_name.removeprefix("popcount").removesuffix("_tree")))
    start = time.time()
    with design_lock(bench_name, ROOT / candidate), contextlib.redirect_stdout(io.StringIO()), formal_context:
        result = runner.evaluate(candidate, benchmark=benchmark, cache=cache, clean=clean)
    result["_started"] = start
    result["_finished"] = time.time()
    return result


def evaluate_many(jobs: list[tuple[str, str]], *, workers: int, cache: bool = True,
                  clean: bool = False) -> list[dict]:
    """jobs: (candidate path relative to ROOT, benchmark name). Order preserved."""
    payload = [(c, b, cache, clean) for c, b in jobs]
    if workers <= 1:
        return [_run(p) for p in payload]
    with ProcessPoolExecutor(max_workers=workers) as pool:
        return list(pool.map(_run, payload))
