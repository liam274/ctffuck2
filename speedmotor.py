#!/usr/bin/python
"""
benchmark.py - Compare execution speed of CTFFuck2 Baby (Python) vs Hardcore (C++).
Generates a test program of N '2's (set) operations, runs both interpreters,
and reports elapsed wall-clock time.
"""

import subprocess
import time
import sys
import os

# Paths (adjust if needed)
HARDCORE_BIN = "./executable/ctffuck2-hardcore"  # after running build.sh
BABY_SCRIPT = "baby-ctffuck2.py"


def generate_test_file(filename, num_instr=1_000_000):
    """Create a .ctf file with a repetition of '2's."""
    print(f"Generating test program with {num_instr:,} instructions in {filename}...")
    with open(filename, "w") as f:
        f.write("2" * num_instr)


def run_cmd(cmd, description):
    """Run command, measure wall time, return elapsed seconds."""
    print(f"  Running: {description}...", end="", flush=True)
    start = time.perf_counter()
    proc = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    end = time.perf_counter()
    elapsed = end - start
    status = "OK" if proc.returncode == 0 else f"FAIL (rc={proc.returncode})"
    print(f" {elapsed:.3f}s ({status})")
    return elapsed


def main():
    test_file = "benchmark_program.ctf"
    instructions = 1_000_000
    runs = 5

    # Generate file
    generate_test_file(test_file, instructions)

    # Check that executables exist
    if not os.path.isfile(HARDCORE_BIN):
        print(
            f"Error: Hardcore binary not found at '{HARDCORE_BIN}'. Build it first (./build.sh)."
        )
        sys.exit(1)
    if not os.path.isfile(BABY_SCRIPT):
        print(f"Error: Baby script not found at '{BABY_SCRIPT}'.")
        sys.exit(1)

    print("\n=========== Benchmarks ===========")

    # --- Hardcore (C++) ---
    hardcore_cmd = [HARDCORE_BIN, "-f", test_file]
    # Warm-up
    run_cmd(hardcore_cmd, "Hardcore warm-up")
    times = []
    for i in range(runs):
        t = run_cmd(hardcore_cmd, f"Hardcore run {i+1}/{runs}")
        times.append(t)
    avg_h = sum(times) / len(times)
    print(f"  Average: {avg_h:.3f}s")

    # --- Baby (Python) ---
    baby_cmd = ["python3", BABY_SCRIPT, "-f", test_file]
    # Warm-up
    run_cmd(baby_cmd, "Baby warm-up")
    times = []
    for i in range(runs):
        t = run_cmd(baby_cmd, f"Baby run {i+1}/{runs}")
        times.append(t)
    avg_b = sum(times) / len(times)
    print(f"  Average: {avg_b:.3f}s")

    # Summary
    speedup = avg_b / avg_h if avg_h > 0 else float("inf")
    print(f"\n=========== Summary for {instructions:,} instructions ===========")
    print(f"Hardcore (C++): {avg_h:.3f} s")
    print(f"Baby (Python):  {avg_b:.3f} s")
    print(f"Speedup:        {speedup:.1f}x")

    # Cleanup
    os.remove(test_file)


if __name__ == "__main__":
    main()
