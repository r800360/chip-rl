"""Agentic RTL optimization eval: Claude models with verification and EDA tools.

Each episode: one task, one model, one tool condition.
  full_tools : simulate, prove_equivalence, estimate_ppa, place_and_route, finish
  pnr_only   : place_and_route, finish (every check costs a scored submission)
Both conditions get the same budget of 4 place_and_route submissions.

Outputs: results/agentic_eval_v1/<episode_id>/{episode.json, transcript.json}
Resumable: finished episodes are skipped.

Run:  python -m experiments.agentic_rtl_eval_v1 --models claude-sonnet-5 \
          --tasks cmp32 --conditions full_tools --reps 1 --workers 4
"""
from __future__ import annotations

import argparse
import itertools
import json
import time
import traceback
from concurrent.futures import ThreadPoolExecutor, as_completed

import anthropic

from chiprl.agentic_env import TASKS, Episode, tool_definitions
from chiprl.benchmarks import ROOT
from chiprl.llm import cost_usd, load_api_key, request_settings

OUT = ROOT / "results" / "agentic_eval_v1"
MAX_API_TURNS = 40
MAX_TOKENS = 32000

SYSTEM = (
    "You are an expert ASIC RTL designer working in a hardware optimization environment. "
    "Improve the given module's post-route score while keeping it exactly equivalent to the "
    "specification. Check correctness and estimate quality with the cheaper tools before "
    "spending the limited place_and_route budget, reason from the measured results, and call "
    "finish when further submissions are unlikely to help."
)


def block_to_dict(block) -> dict:
    return block.model_dump(exclude_none=True) if hasattr(block, "model_dump") else dict(block)


def run_episode(model: str, task_name: str, condition: str, rep: int) -> dict:
    episode_id = f"{task_name}__{condition}__{model}__r{rep}"
    folder = OUT / episode_id
    done = folder / "episode.json"
    if done.is_file():
        return json.loads(done.read_text())
    folder.mkdir(parents=True, exist_ok=True)

    episode = Episode(task=TASKS[task_name], episode_id=episode_id, condition=condition)
    client = anthropic.Anthropic(max_retries=8)
    tools = tool_definitions(condition)
    messages = [{"role": "user", "content": episode.task_prompt()}]
    usage_total: dict[str, int] = {}
    turns, stop, error = 0, None, None
    start = time.time()
    try:
        while not episode.finished and turns < MAX_API_TURNS:
            turns += 1
            with client.messages.stream(
                model=model, max_tokens=MAX_TOKENS, system=SYSTEM, tools=tools,
                messages=messages, cache_control={"type": "ephemeral"},
                **request_settings(model),
            ) as stream:
                response = stream.get_final_message()
            for key, value in response.usage.model_dump().items():
                if isinstance(value, int):
                    usage_total[key] = usage_total.get(key, 0) + value
            messages.append({"role": "assistant", "content": response.content})
            stop = response.stop_reason
            if stop == "refusal":
                break
            tool_uses = [b for b in response.content if b.type == "tool_use"]
            if not tool_uses:
                if stop == "max_tokens":
                    messages.append({"role": "user", "content": "Continue."})
                    continue
                break  # ended the turn without calling finish
            results = []
            for use in tool_uses:
                result, is_error = episode.execute(use.name, dict(use.input))
                results.append({"type": "tool_result", "tool_use_id": use.id,
                                "content": json.dumps(result), "is_error": is_error})
            messages.append({"role": "user", "content": results})
    except Exception as exc:  # keep partial record for audit
        error = f"{type(exc).__name__}: {exc}"
        traceback.print_exc()

    transcript = [
        {"role": m["role"], "content": m["content"] if isinstance(m["content"], str)
         else [block_to_dict(b) for b in m["content"]]}
        for m in messages
    ]
    (folder / "transcript.json").write_text(json.dumps(transcript, indent=1, default=str) + "\n")
    tool_counts: dict[str, int] = {}
    for call in episode.calls:
        tool_counts[call["tool"]] = tool_counts.get(call["tool"], 0) + 1
    record = {
        "episode_id": episode_id, "model": model, "task": task_name,
        "condition": condition, "rep": rep,
        "settings": {"max_tokens": MAX_TOKENS, "pnr_budget": episode.pnr_budget,
                     "max_tool_calls": episode.max_tool_calls, **request_settings(model)},
        "baseline_score": episode.baseline["proxy_reward_v0"],
        "best_known_score": episode.task.best_known()["proxy_reward_v0"],
        **episode.score(),
        "finished_by_agent": bool(episode.finish_summary),
        "finish_summary": episode.finish_summary,
        "api_turns": turns, "last_stop_reason": stop, "error": error,
        "tool_counts": tool_counts, "calls": episode.calls,
        "submissions": episode.submissions,
        "usage": usage_total, "cost_usd": round(cost_usd(model, usage_total), 4),
        "wall_s": round(time.time() - start, 1),
    }
    if error is None:
        done.write_text(json.dumps(record, indent=1) + "\n")
    else:
        (folder / "episode_error.json").write_text(json.dumps(record, indent=1) + "\n")
    return record


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--models", nargs="+", required=True)
    parser.add_argument("--tasks", nargs="+", default=sorted(TASKS))
    parser.add_argument("--conditions", nargs="+", default=["full_tools", "pnr_only"])
    parser.add_argument("--reps", type=int, default=1)
    parser.add_argument("--workers", type=int, default=4)
    args = parser.parse_args()
    load_api_key()
    jobs = list(itertools.product(args.models, args.tasks, args.conditions, range(1, args.reps + 1)))
    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = {pool.submit(run_episode, *job): job for job in jobs}
        for future in as_completed(futures):
            r = future.result()
            print(f"{r['episode_id']}: best={r['best_score']} delta={r['best_minus_baseline']} "
                  f"valid={r['valid_submissions']}/{r['submissions']} tools={r['tool_counts']} "
                  f"cost=${r['cost_usd']} wall={r['wall_s']}s err={r['error']}", flush=True)


if __name__ == "__main__":
    main()
