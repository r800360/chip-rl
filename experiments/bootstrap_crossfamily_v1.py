"""One-time scaffold for preregistered cross-circuit RL study.

Run from the existing ~/fpga/chip-rl checkout:
  python experiments/bootstrap_crossfamily_v1.py freeze
  # Commit/tag the freeze before doing this:
  python experiments/bootstrap_crossfamily_v1.py scaffold
  python experiments/bootstrap_crossfamily_v1.py verify

Never performs EDA, does not edit old policy implementations or old results.
"""
from __future__ import annotations

import hashlib
import json
import re
import subprocess
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
EXPECTED_ARCHIVE_SHA = '87ec1038e99af074674978d5323e685464a9ab346df386783158816850ffca8a'
FAMILIES = ('cmp32', 'popcount32', 'priority32')
RNG_SEEDS = (20260923, 20260924, 20260925)
FROZEN_SOURCE = {
    'experiments/addpipe36_reinforce_v1.py': '4b082c3ba6ac950bc8f6328b9672d357bd34139820b1c5e97ad115ef17caaba1',
    'chiprl/autoregressive_policy.py': '8441ee22e82388f4f7ccf2fbf1c9abcb917be32f8cbe2012c7ffec37b9449e95',
    'chiprl/rl_env.py': '0573cd00111e4b24c751647f2f80f05aaabbff1425817f3684c991399339cdea',
}


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def write_new(name: str, content: str):
    path = ROOT / name
    if path.exists():
        raise FileExistsError(f'refusing to overwrite {path}')
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)
    print('CREATE', name)


def freeze():
    archive = ROOT / 'results/multiwidth_generalization_v1/multiwidth_results_bundle.zip'
    if not archive.is_file():
        raise FileNotFoundError(f'expected your experiment archive at {archive}')
    if sha(archive) != EXPECTED_ARCHIVE_SHA:
        raise RuntimeError('experiment archive digest differs from the uploaded verified archive')
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        s = json.loads(z.read('results/multiwidth_generalization_v1/compact_summary.json'))
    assert s['total_search_queries'] == 240
    rows = s['summary']
    assert len(rows) == 15
    assert {(r['benchmark'], r['algorithm']) for r in rows} == {
        (f'addpipe{w}', m) for w in (36, 48, 56)
        for m in ('random', 'evolution', 'reinforce_v1',
                  'reinforce_v2', 'claude_structural')
    }
    assert all(r['queries'] == 16 and r['successful_queries'] == 16
               and r['duplicate_query_masks'] == 0 for r in rows)
    for name, h in FROZEN_SOURCE.items():
        if sha(ROOT / name) != h:
            raise RuntimeError(f'original frozen implementation differs: {name}')
    manifest = {
        'status': 'FROZEN_NO_FURTHER_MULTIWIDTH_SEARCH',
        'benchmark_widths': [36, 48, 56],
        'algorithm_count': 5, 'search_query_count': 240,
        'all_saved_queries_valid': True,
        'bundle_path': str(archive.relative_to(ROOT)),
        'bundle_sha256': EXPECTED_ARCHIVE_SHA,
        'source_sha256': FROZEN_SOURCE,
        'per_method_summary': rows,
        'git_head_before_freeze': subprocess.check_output(
            ['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True
        ).strip(),
        'limitations': ('Fixed ORFS image and physical setup; three sizes of '
                        'one adder family, not independent hardware task families. '
                        'No validated fmax, no activity-based power estimate.'),
    }
    write_new('experiments/multiwidth_final_freeze_v1.json',
              json.dumps(manifest, indent=2, sort_keys=True) + '\n')
    print('PASS: original 240-query study packaged and frozen; commit/tag next')


def reference(family):
    ybits = 1 if family == 'cmp32' else 6
    if family == 'cmp32':
        calc = 'wire [0:0] computed = (a_i < b_i);'
    elif family == 'popcount32':
        calc = '''reg [5:0] computed;
integer i;
always @* begin
    computed = 6'd0;
    for (i = 0; i < 32; i = i + 1)
        computed = computed + a_i[i];
end'''
    else:
        calc = '''reg [5:0] computed;
integer i;
always @* begin
    computed = 6'd0;
    for (i = 0; i < 32; i = i + 1)
        if (a_i[i]) computed = {1'b1, i[4:0]};
end'''
    return f'''module {family}_ref (
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire [31:0] a_i,
    input wire [31:0] b_i,
    output reg valid_o,
    output reg [{ybits-1}:0] y_o
);
{calc}
always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        y_o <= {ybits}'d0;
    end else begin
        valid_o <= valid_i;
        if (valid_i)
            y_o <= computed;
    end
end
endmodule
'''


def tb(family):
    ybits = 1 if family == 'cmp32' else 6
    if family == 'cmp32':
        calculate = 'expected = (a < b);'
    elif family == 'popcount32':
        calculate = 'expected = $countones(a);'
    else:
        calculate = '''expected = 6'd0;
    for (int j = 0; j < 32; j = j + 1)
        if (a[j]) expected = {1'b1, j[4:0]};'''
    return f'''`timescale 1ns/1ps
module tb;
logic clk, rst_n, valid_i;
logic [31:0] a_i, b_i;
wire valid_o;
wire [{ybits-1}:0] y_o;
logic [{ybits-1}:0] last_y;
logic [63:0] rng;
{family} dut (.*);
initial clk = 1'b0;
always #5 clk = ~clk;

function automatic [63:0] next_rng(input [63:0] x);
  reg [63:0] y;
  begin
    y = x; y = y ^ (y << 13);
    y = y ^ (y >> 7); y = y ^ (y << 17);
    next_rng = y;
  end
endfunction

task automatic check(input [31:0] a, input [31:0] b);
  logic [{ybits-1}:0] expected;
  begin
    {calculate}
    @(negedge clk);
    a_i = a; b_i = b; valid_i = 1'b1;
    @(posedge clk); #1;
    if (valid_o !== 1'b1 || y_o !== expected)
      $fatal(1, "valid result mismatch: a=%h b=%h got=%h expected=%h", a,b,y_o,expected);
    last_y = expected;
    @(negedge clk);
    a_i = ~a; b_i = b ^ 32'ha55aa55a; valid_i = 1'b0;
    @(posedge clk); #1;
    if (valid_o !== 1'b0 || y_o !== last_y)
      $fatal(1, "invalid-cycle output was not held");
  end
endtask

task automatic back_to_back(input [31:0] a0, b0, a1, b1);
  logic [{ybits-1}:0] expected;
  begin
    @(negedge clk);
    a_i = a0; b_i = b0; valid_i = 1'b1;
    // Distinct first result is checked using the same arithmetic oracle.
    {calculate.replace('a < b', 'a0 < b0').replace('$countones(a)', '$countones(a0)').replace('a[j]', 'a0[j]')}
    @(posedge clk); #1;
    if (valid_o !== 1'b1 || y_o !== expected)
      $fatal(1, "first back-to-back result failed");
    @(negedge clk);
    a_i = a1; b_i = b1; valid_i = 1'b1;
    {calculate.replace('a < b', 'a1 < b1').replace('$countones(a)', '$countones(a1)').replace('a[j]', 'a1[j]')}
    @(posedge clk); #1;
    if (valid_o !== 1'b1 || y_o !== expected)
      $fatal(1, "second back-to-back result failed");
    last_y = expected;
  end
endtask

initial begin
  rst_n = 1'b0; valid_i = 1'b0; a_i = 0; b_i = 0;
  last_y = {ybits}'d0; rng = 64'h243f6a8885a308d3;
  repeat (3) begin
    @(posedge clk); #1;
    if (valid_o !== 1'b0 || y_o !== {ybits}'d0)
      $fatal(1, "reset protocol failed");
  end
  @(negedge clk); rst_n = 1'b1;
  check(32'h00000000, 32'h00000000);
  check(32'hffffffff, 32'h00000001);
  check(32'h80000000, 32'h7fffffff);
  check(32'h55555555, 32'haaaaaaaa);
  check(32'h00000001, 32'h00000000);
  check(32'hffffffff, 32'hffffffff);
  for (int i = 0; i < 10000; i = i + 1) begin
    rng = next_rng(rng); a_i = rng[31:0];
    rng = next_rng(rng); b_i = rng[31:0];
    check(a_i, b_i);
  end
  back_to_back(32'h01234567,32'hfedcba98,32'h90000001,32'h00000000);
  $display("PASS {family} randomized+protocol");
  $finish;
end
endmodule
'''


def seed_masks():
    from chiprl.circuit_family_generators import mask_from_blocks
    b = [(32,), (8,24), (16,16), (24,8), (8,8,8,8),
         (4,)*8, (2,)*16, (1,)*32]
    return b, [mask_from_blocks(x) for x in b]


def scaffold():
    freeze_path = ROOT / 'experiments/multiwidth_final_freeze_v1.json'
    if not freeze_path.exists():
        raise RuntimeError('freeze and commit/tag the prior study first')
    for name, h in FROZEN_SOURCE.items():
        if sha(ROOT / name) != h:
            raise RuntimeError(f'freeze guard failed: {name}')
    if not (ROOT / 'chiprl/circuit_family_generators.py').is_file():
        raise RuntimeError('copy circuit_family_generators.py into chiprl/ first')

    from chiprl.circuit_family_generators import write_candidate, blocks_from_mask
    blocks, masks = seed_masks()
    assert len(masks) == len(set(masks)) == 8

    protocol = {
        'experiment_id': 'crossfamily_policy_causality_v1',
        'status': 'PREREGISTERED_BEFORE_ANY_NEW_FAMILY_PPA',
        'background': 'post-addpipe observational follow-up; no policy tuning',
        'families': list(FAMILIES),
        'datapath_width': 32, 'mask_bits': 31, 'mask_space': 1 << 31,
        'output_semantics': {
            'cmp32': 'unsigned a < b, one-bit registered output',
            'popcount32': 'number of asserted bits in a, six-bit registered output',
            'priority32': 'highest asserted bit in a, six-bit {found,index} output; zero if none',
        },
        'clock_ns': 10.0,
        'platform': 'Nangate45',
        'die': [0,0,100,100], 'core': [5,5,95,95],
        'place_density': 0.20,
        'formal_seq': 4,
        'testbench': '10,000 fixed-seed random pairs plus directed, reset, invalid hold and back-to-back tests',
        'seed_blocks': [list(x) for x in blocks],
        'shared_seed_masks': [f'0x{m:08x}' for m in masks],
        'physical_seed_queries': 8 * 3,
        'search_methods': [
            'v1_learn', 'v2_learn', 'v2_frozen', 'count_matched_uniform',
        ],
        'search_policy_seeds': list(RNG_SEEDS),
        'budget_per_run': 16,
        'logical_search_queries': 3 * 4 * 3 * 16,
        'reward': 'proxy_reward_v0 = -0.001*area + 10.0*WNS; fail -1000',
        'evaluation_gate': 'simulation -> sequential formal -> ORFS through GDS',
        'method_definitions': {
            'v1_learn': 'unmodified frozen independent-Bernoulli REINFORCE code, adjusted only for 31 bits and run seed',
            'v2_learn': 'unmodified frozen hierarchical count/ordered-position policy with score-based online update',
            'v2_frozen': 'EXACT same v2 initializer and sampler but NO updates',
            'count_matched_uniform': 'exact initial v2 K distribution; positions chosen uniformly without replacement; no updates; differs from frozen v2 in positional prior AND ordered-sampler geometry',
        },
        'analysis': {
            'primary': [
                'v2_learn minus v2_frozen in per-task/run final seed-relative reward',
                'v2_frozen minus count_matched_uniform (combined position prior + ordered sampling geometry versus sparsity-only) in per-task/run final seed-relative reward',
                'v2_learn minus v1_learn in per-task/run final seed-relative reward',
            ],
            'secondary': ['first scalar improvement query (censor failures at 17)',
                          'improvement frequency', 'Pareto additions', 'mean boundary count',
                          'exact proposed-mask overlap'],
            'limitations': ['three task families at one width',
                            'three pseudorandom trajectories each, same EDA setup',
                            'v2 positional logits are context-shared except for monotone availability',
                            'duplicate-rejection changes effective proposal distribution',
                            'seeds and physical design chosen after prior adder-family observations',
                            'fixed placement/tool seed; no multi-PDK robustness'],
        },
        'information_rule': 'each method sees shared seed measurements and only its own past queries',
        'shared_physical_cache': 'allowed; count logical queries separately from physical cache misses',
        'fmax': 'UNTRUSTED; record only, never use in conclusions',
        'power': 'rough tool-reported power, not activity validated',
        'frozen_source_sha256': FROZEN_SOURCE,
        'bootstrap_sha256': sha(Path(__file__)),
        'generators_sha256': sha(ROOT / 'chiprl/circuit_family_generators.py'),
        'runner_sha256': sha(ROOT / 'experiments/crossfamily_runner.py'),
        'shared_runner_sha256': sha(ROOT / 'experiments/crossfamily_shared_seeds.py'),
    }

    # Avoid partial mutation if the experiment was already created.
    intended = [
        f'rtl/reference/{f}_ref.v' for f in FAMILIES
    ] + [f'rtl/{f}/baseline.v' for f in FAMILIES] + [
        f'sim/tb_{f}.sv' for f in FAMILIES
    ] + [f'orfs/{f}/config.mk' for f in FAMILIES] + [
        f'orfs/{f}/constraint.sdc' for f in FAMILIES
    ] + ['experiments/protocol_crossfamily_v1.json']
    present = [p for p in intended if (ROOT / p).exists()]
    if present:
        raise FileExistsError(f'study scaffold already exists; refusing overwrite: {present}')

    template_config = (ROOT / 'orfs/addpipe36/config.mk').read_text()
    template_sdc = (ROOT / 'orfs/addpipe36/constraint.sdc').read_text()
    for f in FAMILIES:
        write_new(f'rtl/reference/{f}_ref.v', reference(f))
        path = ROOT / f'rtl/{f}/baseline.v'
        write_candidate(f, 0, path)
        print('CREATE', path.relative_to(ROOT))
        write_new(f'sim/tb_{f}.sv', tb(f))
        config = template_config.replace('addpipe36', f)
        config = re.sub(r'(?m)^(export DIE_AREA\s*=).+$', r'\g<1> 0 0 100 100', config)
        config = re.sub(r'(?m)^(export CORE_AREA\s*=).+$', r'\g<1> 5 5 95 95', config)
        write_new(f'orfs/{f}/config.mk', config)
        sdc = re.sub(r'(?m)^current_design\s+\S+', f'current_design {f}', template_sdc)
        write_new(f'orfs/{f}/constraint.sdc', sdc)

    registry = ROOT / 'chiprl/benchmarks.py'
    src = registry.read_text()
    if any(f'"{f}": Benchmark(' in src for f in FAMILIES):
        raise RuntimeError('one or more study benchmarks already registered')
    marker = '\n}\n\n\ndef get_benchmark'
    if src.count(marker) != 1:
        raise RuntimeError('cannot uniquely find benchmark registry end')
    entries = ''.join(f'''    "{f}": Benchmark(
        name="{f}",
        top_module="{f}",
        reference_top="{f}_ref",
        testbench=ROOT / "sim/tb_{f}.sv",
        reference=ROOT / "rtl/reference/{f}_ref.v",
        orfs_config_host=ROOT / "orfs/{f}/config.mk",
        orfs_config_container="/work/orfs/{f}/config.mk",
        sdc=ROOT / "orfs/{f}/constraint.sdc",
        pass_marker="PASS {f} randomized+protocol",
    ),
''' for f in FAMILIES)
    registry.write_text(src.replace(marker, '\n' + entries + '}\n\n\ndef get_benchmark'))
    print('UPDATE chiprl/benchmarks.py')

    evaluator = ROOT / 'chiprl/evaluate.py'
    src = evaluator.read_text()
    if any(f'"{f}"' in src for f in FAMILIES):
        raise RuntimeError('one or more study benchmarks already in evaluator choices')
    choices_marker = '            "addpipe56",\n'
    if src.count(choices_marker) != 1:
        raise RuntimeError('cannot uniquely find CLI choices insertion marker')
    choices = ''.join(f'            "{f}",\n' for f in FAMILIES)
    evaluator.write_text(src.replace(choices_marker, choices_marker + choices))
    print('UPDATE chiprl/evaluate.py')

    write_new('experiments/protocol_crossfamily_v1.json',
              json.dumps(protocol, indent=2, sort_keys=True) + '\n')
    print('PASS: scaffold created. COMMIT before any new physical measurement.')


def verify():
    from chiprl.benchmarks import get_benchmark
    from chiprl.circuit_family_generators import render, blocks_from_mask, python_oracle
    import random
    p = ROOT / 'experiments/protocol_crossfamily_v1.json'
    cfg = json.loads(p.read_text())
    assert tuple(cfg['families']) == FAMILIES
    assert cfg['logical_search_queries'] == 576
    masks = [int(x, 0) for x in cfg['shared_seed_masks']]
    assert len(masks) == len(set(masks)) == 8
    assert all(sum(blocks_from_mask(m)) == 32 for m in masks)
    for f in FAMILIES:
        bench = get_benchmark(f)
        for attr in ('testbench','reference','orfs_config_host','sdc'):
            assert getattr(bench, attr).exists()
        for m in masks:
            rtl = render(f, m)
            assert f'module {f} (' in rtl
            assert 'valid_o <= valid_i;' in rtl
        rng = random.Random(42)
        for _ in range(1000):
            a, b = rng.getrandbits(32), rng.getrandbits(32)
            result = python_oracle(f, a, b)
            assert (0 <= result <= (1 if f == 'cmp32' else 63))
        print('PASS', f, 'generated eight seed RTLs and checked Python oracle ranges')
    print('PASS: zero-EDA scaffold audit. Formal + Verilator still REQUIRED on your machine.')


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in ('freeze','scaffold','verify'):
        raise SystemExit('usage: python experiments/bootstrap_crossfamily_v1.py freeze|scaffold|verify')
    {'freeze': freeze, 'scaffold': scaffold, 'verify': verify}[sys.argv[1]]()

if __name__ == '__main__':
    main()
