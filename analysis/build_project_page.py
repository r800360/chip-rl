"""Build docs/project_page.html: a single-file, datasheet-style project page.

Numbers are read from frozen result files; figures are embedded as data URIs.
"""
from __future__ import annotations

import base64
import html
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FIG = ROOT / "docs" / "figures"


def data_uri(name: str) -> str:
    path = FIG / name
    mime = "image/jpeg" if path.suffix == ".jpg" else "image/gif" if path.suffix == ".gif" else "image/png"
    return f"data:{mime};base64," + base64.b64encode(path.read_bytes()).decode()


def load(rel: str) -> dict:
    return json.loads((ROOT / rel).read_text())


def numbers() -> dict:
    n = load("results/analysis/project_numbers.json")
    return n


CSS = """
:root{
  --paper:#f6f7f9; --sheet:#ffffff; --ink:#11151c; --ink-2:#4a5160; --muted:#7b8190;
  --rule:#d8dce3; --rule-strong:#11151c; --accent:#2a78d6; --accent-ink:#1c5cab; --hot:#c4501f;
  --code:#eef1f5; --good:#1f7a36;
}
@media (prefers-color-scheme: dark){
  :root:not([data-theme="light"]){
    --paper:#0e1116; --sheet:#151920; --ink:#e7e9ee; --ink-2:#a9afbb; --muted:#7f8694;
    --rule:#2a303a; --rule-strong:#e7e9ee; --accent:#5b9be6; --accent-ink:#8cbaf0; --hot:#ec835a;
    --code:#1c222b; --good:#4cc26a; color-scheme:dark;
  }
}
:root[data-theme="dark"]{
  --paper:#0e1116; --sheet:#151920; --ink:#e7e9ee; --ink-2:#a9afbb; --muted:#7f8694;
  --rule:#2a303a; --rule-strong:#e7e9ee; --accent:#5b9be6; --accent-ink:#8cbaf0; --hot:#ec835a;
  --code:#1c222b; --good:#4cc26a; color-scheme:dark;
}
body{background:var(--paper);color:var(--ink);font:15px/1.6 "IBM Plex Sans",system-ui,-apple-system,"Segoe UI",sans-serif;padding-inline:16px;padding-block:28px 56px}
.sheet{max-width:1060px;margin:0 auto;background:var(--sheet);border:1px solid var(--rule);padding:clamp(18px,4vw,44px)}
h1,h2,h3{font-family:"IBM Plex Sans Condensed","IBM Plex Sans",system-ui,sans-serif;text-wrap:balance;margin:0}
.mono,code,.num{font-family:"IBM Plex Mono",ui-monospace,SFMono-Regular,Menlo,monospace}
code{background:var(--code);padding:.05em .35em;border-radius:3px;font-size:.88em}
.masthead{display:grid;grid-template-columns:1fr auto;gap:10px 24px;align-items:end;border-bottom:3px solid var(--rule-strong);padding-bottom:14px}
.part{font-size:clamp(40px,7vw,64px);font-weight:700;letter-spacing:.01em;line-height:1}
.part small{font-size:.32em;font-weight:500;color:var(--muted);letter-spacing:.08em;margin-left:.6em;vertical-align:middle}
.tagline{grid-column:1/-1;font-size:clamp(17px,2.4vw,21px);color:var(--ink-2);font-weight:500}
.meta{font-size:12.5px;color:var(--muted);text-align:right;letter-spacing:.04em;text-transform:uppercase}
.strip{display:flex;flex-wrap:wrap;gap:6px 14px;font-size:12.5px;color:var(--ink-2);padding:10px 0 0;letter-spacing:.03em;text-transform:uppercase}
.strip span{white-space:nowrap}
section{padding-top:30px}
h2{font-size:15px;font-weight:700;text-transform:uppercase;letter-spacing:.12em;color:var(--ink);border-bottom:1px solid var(--rule);padding-bottom:6px;margin-bottom:14px;display:flex;gap:10px;align-items:baseline}
h2 .sec{color:var(--accent);font-family:"IBM Plex Mono",monospace;font-size:13px;letter-spacing:0}
.front{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1.15fr);gap:28px}
@media (max-width:820px){.front{grid-template-columns:1fr}.masthead{grid-template-columns:1fr}.meta{text-align:left}}
ul.features{margin:0;padding-left:1.1em;display:grid;gap:7px}
ul.features li::marker{color:var(--accent)}
figure{margin:0}
figure img{display:block;width:100%;height:auto;border:1px solid var(--rule);background:#fcfcfb}
figcaption{font-size:12.5px;color:var(--muted);margin-top:6px}
.tablewrap{overflow-x:auto}
table{border-collapse:collapse;width:100%;font-size:14px;font-variant-numeric:tabular-nums}
th{text-align:left;font-family:"IBM Plex Sans Condensed",sans-serif;font-weight:600;text-transform:uppercase;letter-spacing:.06em;font-size:12px;color:var(--ink-2);border-bottom:2px solid var(--rule-strong);padding:6px 10px 6px 0}
td{border-bottom:1px solid var(--rule);padding:8px 10px 8px 0;vertical-align:top}
td.val{font-family:"IBM Plex Mono",monospace;font-size:13.5px;white-space:nowrap;color:var(--ink)}
td.cond{color:var(--ink-2);font-size:13.5px}
.finding{display:grid;grid-template-columns:minmax(0,.85fr) minmax(0,1.4fr);gap:22px;padding:18px 0;border-bottom:1px solid var(--rule)}
.finding:last-child{border-bottom:0}
@media (max-width:820px){.finding{grid-template-columns:1fr}}
.finding h3{font-size:20px;font-weight:600;margin-bottom:6px}
.finding .big{font-family:"IBM Plex Mono",monospace;font-size:26px;font-weight:600;color:var(--accent-ink);display:block;margin:4px 0 8px}
.finding p{margin:0 0 8px;color:var(--ink-2);max-width:62ch}
.rev td:first-child{font-family:"IBM Plex Mono",monospace;white-space:nowrap;color:var(--ink-2)}
.notes{columns:2 320px;column-gap:28px;color:var(--ink-2);font-size:14px}
.notes p{margin:0 0 8px;break-inside:avoid}
.foot{margin-top:28px;padding-top:12px;border-top:3px solid var(--rule-strong);font-size:12.5px;color:var(--muted);display:flex;flex-wrap:wrap;gap:6px 18px;justify-content:space-between}
a{color:var(--accent-ink)}
a:focus-visible{outline:2px solid var(--accent);outline-offset:2px}
"""


def build() -> Path:
    n = numbers()
    features = [
        "Verification-gated reward: Verilator simulation, then Yosys sequential equivalence, then OpenROAD RTL-to-GDS; unverified designs score -1000",
        f"Decomposed formal proofs for reduction trees: {n['formal_per_candidate_s']} s per design instead of 70+ minutes",
        "Content-addressed, bit-reproducible evaluations (RTL, flow, container and tool versions hashed)",
        "Query-budgeted RL environment with duplicate rejection, exact replay and frozen-policy controls",
        "Tool-using agent environment for Claude: simulate, prove, estimate, budgeted place-and-route",
        f"Stage-proxy screening: floorplan timing ranks designs with rho {n['mf_floorplan_rho']} at {n['mf_floorplan_time']} of tool time",
        f"{n['routed_designs']:,} routed designs, 15 benchmark widths and families, 20+ preregistered studies",
    ]
    chars = [
        ("Evaluation latency", "one design, one worker, median", f"{n['latency_total_s']} s"),
        ("Throughput", f"{n['best_workers']} parallel workers, {n['cpus']} CPUs", f"{n['best_rate']} designs/h ({n['best_speedup']}x)"),
        ("Formal proof, lane-sum tree", "per candidate / one-time certificate", f"{n['formal_per_candidate_s']} s / {n['formal_cert_s']} s"),
        ("Formal proof, monolithic", "MiniSat, Glucose, CaDiCaL", "no result in 120 s"),
        ("Proxy fidelity", f"floorplan stage, {n['mf_benchmarks']} benchmarks", f"median rho {n['mf_floorplan_rho']}"),
        ("Screening recall", "true best kept in top 25%", f"{n['mf_kept']}"),
        ("Reward hacks admitted", "after the formal gate", "0"),
        ("Learning vs frozen policy", f"{n['rl_pairs']} matched pairs, 4 studies", f"{n['rl_signs']}"),
        ("Agentic eval", f"{n['agent_episodes']} episodes, 3 Claude models", f"{n['agent_improved']} improved"),
        ("API cost", "whole agentic eval", f"${n['agent_cost']}"),
    ]
    findings = [
        ("Reward hacking on day one", "5 of 10",
         "Under a loose testbench, every spec-violating 8-bit adder beat its correct twin by dropping the output-hold enable (10 to 15% less area). Sequential equivalence against a reference now gates every reward.",
         "reward_hacking_loose_spec.png"),
        ("Verification that scales", f"{n['formal_speedup']}",
         "Proving a 16-lane adder tree against a sequential accumulator has no shared internal signals, so SAT stalls. Cut-point proofs plus a 47-step rewrite certificate prove it in seconds and still reject 7 of 7 injected bugs.",
         "formal_scaling.png"),
        ("Proxy rewards for EDA latency", f"rho {n['mf_floorplan_rho']}",
         f"Static timing at the floorplan stage predicts the post-route ranking across {n['mf_designs']:,} designs. Synthesis area alone does not (median rho {n['mf_synth_rho']}).",
         "multifidelity_proxy.png"),
        ("RL under controls", n["rl_signs"],
         "Hierarchical REINFORCE beat a factorized one on fresh adder widths, but identical frozen policies matched it. I fixed a policy-gradient bias from rejection sampling and traced the real limit to search coverage.",
         "rl_learning_vs_frozen.png"),
        ("Claude as an RTL agent", n["agent_headline"], n["agent_text"], "agentic_eval_outcomes.png"),
    ]
    revisions = n["revisions"]

    feat_html = "".join(f"<li>{html.escape(f)}</li>" for f in features)
    char_html = "".join(
        f"<tr><td>{html.escape(a)}</td><td class='cond'>{html.escape(b)}</td><td class='val'>{html.escape(c)}</td></tr>"
        for a, b, c in chars)
    find_html = "".join(
        f"<div class='finding'><div><h3>{html.escape(t)}</h3><span class='big'>{html.escape(big)}</span>"
        f"<p>{html.escape(p)}</p></div><figure><img alt='{html.escape(t)}' src='{data_uri(img)}'></figure></div>"
        for t, big, p, img in findings)
    rev_html = "".join(f"<tr><td>{html.escape(d)}</td><td>{html.escape(m)}</td></tr>" for d, m in revisions)
    pipeline_svg = (FIG / "pipeline.svg").read_text()
    pipeline_svg = pipeline_svg[pipeline_svg.index("<svg"):]

    page = f"""<title>Chip-RL</title>
<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;600&family=IBM+Plex+Sans+Condensed:wght@500;600;700&family=IBM+Plex+Sans:wght@400;500;600&display=swap">
<style>{CSS}</style>
<main class="sheet">
  <header class="masthead">
    <h1 class="part">CHIP-RL<small>REV 1.0</small></h1>
    <div class="meta">Rohan Sachdeva<br>September 2026</div>
    <p class="tagline">A formally verified, physically evaluated reinforcement-learning environment for RTL optimization.</p>
  </header>
  <div class="strip"><span>Verilog RTL</span><span>Verilator</span><span>Yosys equivalence</span><span>OpenROAD</span><span>Nangate45</span><span>KLayout</span><span>Python</span><span>Claude API</span></div>

  <section class="front">
    <div><h2><span class="sec">1</span>Features</h2><ul class="features">{feat_html}</ul></div>
    <div><h2><span class="sec">2</span>Block diagram</h2><figure><div style="overflow-x:auto;border:1px solid var(--rule);background:#fcfcfb">{pipeline_svg}</div>
      <figcaption>Every proposer (Claude, RL policies, baselines) submits RTL to the same verify-then-measure evaluator.</figcaption></figure></div>
  </section>

  <section><h2><span class="sec">3</span>Characteristics</h2>
    <div class="tablewrap"><table><thead><tr><th>Parameter</th><th>Conditions</th><th>Value</th></tr></thead><tbody>{char_html}</tbody></table></div>
  </section>

  <section><h2><span class="sec">4</span>Findings</h2>{find_html}</section>

  <section><h2><span class="sec">5</span>Layout</h2>
    <figure><img alt="Routed layouts" src="{data_uri('layout_gallery.jpg')}"><figcaption>Rendered from the routed Nangate45 GDS: full die from OpenROAD, 30 x 30 um close-ups from KLayout.</figcaption></figure>
  </section>

  <section class="rev"><h2><span class="sec">6</span>Revision history</h2>
    <div class="tablewrap"><table><thead><tr><th>Date</th><th>Change</th></tr></thead><tbody>{rev_html}</tbody></table></div>
  </section>

  <section><h2><span class="sec">7</span>Notes</h2><div class="notes">
    <p>Open 45 nm library and the OpenROAD flow: no commercial tools, multi-corner signoff, activity-based power or tapeout.</p>
    <p>Blocks are small (tens to about a thousand cells) at low utilization and a 10 ns clock. The reward, 10 x WNS - 0.001 x area, is a proxy that weights slack heavily.</p>
    <p>RL studies use 3 random seeds per condition and 16-query budgets: enough to falsify large claims, not to measure small effects.</p>
    <p>"Formally verified" means proven sequentially equivalent to a reference module, not timing or physical signoff.</p>
  </div></section>

  <div class="foot"><span>Docs: README, ARCHITECTURE, RESULTS, JOURNEY, RTL_GALLERY, INTERVIEW_GUIDE</span><span class="mono">chip-rl v1.0</span></div>
</main>
"""
    out = ROOT / "docs" / "project_page.html"
    out.write_text(page)
    return out


if __name__ == "__main__":
    print(build())
