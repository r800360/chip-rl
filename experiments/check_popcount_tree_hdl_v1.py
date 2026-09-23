"""Run new popcount-tree candidate RTL through Verilator and sequential formal.

NO physical synthesis, placement, routing or proxy reward measurements.
Checks all eight preregistered architectures; failures preserve diagnostics.
"""
from __future__ import annotations

import subprocess
from pathlib import Path

from chiprl.benchmarks import ROOT, get_benchmark
from chiprl.formal import check_equivalence
from chiprl.popcount_tree_generator import NAME, PILOT_MASKS


def main():
    bench=get_benchmark(NAME)
    out=ROOT/'results/popcount32_tree_arch_hdl_check'
    out.mkdir(parents=True,exist_ok=True)
    for i,mask in enumerate(PILOT_MASKS,1):
        rtl=ROOT/'rtl/generated/popcount32_tree_arch_seed'/f'mask_{mask:08x}.v'
        print(f'[{i}/8] 0x{mask:08x} RTL simulation + formal',flush=True)
        mdir=ROOT/'.chiprl/verilator'/f'tree_arch_hdl_{mask:08x}'
        mdir.mkdir(parents=True,exist_ok=True)
        build=subprocess.run(['verilator','--binary','--timing','-Wall','-Wno-fatal',
                              '--Mdir',str(mdir),str(rtl),str(bench.testbench),
                              '--top-module','tb'],cwd=ROOT,capture_output=True,text=True)
        (out/f'{mask:08x}_compile.log').write_text(build.stdout+build.stderr)
        if build.returncode:
            raise RuntimeError(f'Verilator compile failed 0x{mask:08x}; see {out}')
        sim=subprocess.run([str(mdir/'Vtb')],cwd=ROOT,capture_output=True,text=True)
        (out/f'{mask:08x}_sim.log').write_text(sim.stdout+sim.stderr)
        if sim.returncode or bench.pass_marker not in sim.stdout:
            raise RuntimeError(f'Verilator protocol simulation failed 0x{mask:08x}; see {out}')
        formal=check_equivalence(rtl,bench)
        (out/f'{mask:08x}_formal.log').write_text(formal['formal_output'])
        if not formal['formal_ok']:
            raise RuntimeError(f'Sequential formal equivalence failed 0x{mask:08x}; see {out}')
        print(f'PASS 0x{mask:08x}: simulation and formal (t={formal["formal_runtime_s"]}s)',flush=True)
    print('PASS: all 8 pilot candidates are simulated and formally equivalent')
    print('NOTE: physical architecture diversity has NOT been tested yet')


if __name__=='__main__':
    main()
