#!/usr/bin/env python3
"""
speedmotor_perf.py – Benchmark CTFFuck2 interpreters with hardware counters.
Works on hybrid CPUs (atom + core) by summing per-type events.
"""

import subprocess
import sys
import os
import re
import statistics

HARDCORE_BIN = "./executable/ctffuck2"
INSTRUCTIONS = 10_000_000  # digits in the test program


def generate_test_file(filename, num_instr):
    print(f"Generating test file with {num_instr:,} instructions ...")
    with open(filename, "w") as f:
        f.write("2" * num_instr)


def run_perf(cmd, description, runs=100):
    """
    Run cmd under 'perf stat -e cycles,instructions'.
    Parse output that may contain per-core-type lines (e.g. cpu_atom/cycles/u).
    Returns (avg_cycles, avg_instructions, avg_seconds).
    """
    cycles_vals = []
    ins_vals = []
    times_vals = []
    for i in range(runs):
        print(f"  {description} run {i+1}/{runs} ...", end="", flush=True)
        proc = subprocess.run(
            ["perf", "stat", "-e", "cycles,instructions", "--"] + cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.PIPE,
            text=True,
        )
        stderr = proc.stderr

        # Sum all cycles and instructions from any line containing the keyword.
        cycles_total = 0
        ins_total = 0
        for line in stderr.splitlines():
            if "cycles" in line:
                # match the number at start of line or after whitespace
                match = re.search(r"([\d,]+)\s", line)
                if match:
                    cycles_total += int(match.group(1).replace(",", ""))
            if "instructions" in line:
                match = re.search(r"([\d,]+)\s", line)
                if match:
                    ins_total += int(match.group(1).replace(",", ""))

        # Parse elapsed time
        time_match = re.search(r"([\d.]+)\s+seconds time elapsed", stderr)
        secs = float(time_match.group(1)) if time_match else 0.0

        if cycles_total == 0 and ins_total == 0:
            print(f" FAIL (could not parse perf output:\n{stderr})")
            continue

        cycles_vals.append(cycles_total)
        ins_vals.append(ins_total)
        times_vals.append(secs)
        print(f" {cycles_total:,} cycles, {ins_total:,} instructions, {secs:.3f}s")

    if not cycles_vals:
        raise RuntimeError("No valid perf runs. Check output above.")
    avg_cycles = statistics.mean(cycles_vals)
    avg_ins = statistics.mean(ins_vals)
    avg_time = statistics.mean(times_vals)
    return avg_cycles, avg_ins, avg_time


def main():
    test_file = "benchmark_program.ctf"

    if not os.path.isfile(HARDCORE_BIN):
        print(f"Error: Hardcore binary not found at '{HARDCORE_BIN}'.")
        sys.exit(1)

    if subprocess.run(["which", "perf"], capture_output=True).returncode != 0:
        print("Error: 'perf' not found. Install it (e.g., sudo pacman -S perf).")
        sys.exit(1)

    generate_test_file(test_file, INSTRUCTIONS)

    print("\n=========== Benchmarks (perf stat) ===========")
    hardcore_cmd = [HARDCORE_BIN, "-f", test_file]

    print("\nHardcore (C++)")
    h_cycles, h_ins, h_time = run_perf(hardcore_cmd, "Hardcore", 100)

    print("\n==================================================")
    print(f"Results for {INSTRUCTIONS:,} instructions (digits)")
    print(
        f"Hardcore (C++) :  {h_cycles:>15,} cycles, {h_ins:>15,} CPU instructions, {h_time:.3f} s"
    )

    h_cyc_per_digit = h_cycles / INSTRUCTIONS
    h_ins_per_digit = h_ins / INSTRUCTIONS

    print(f"\nPer CTFFuck2 digit:")
    print(
        f"Hardcore :  {h_cyc_per_digit:7.2f} cycles, {h_ins_per_digit:7.2f} CPU instructions"
    )

    os.remove(test_file)


if __name__ == "__main__":
    main()
