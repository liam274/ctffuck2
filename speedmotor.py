#!/usr/bin/env python3
"""speedmotor_corrected.py – reliable CTFFuck2 benchmark with live CPU frequency"""

import subprocess
import time
import sys
import os
import statistics

HARDCORE_BIN = "./executable/ctffuck2-hardcore"
BABY_SCRIPT = "baby-ctffuck2.py"

# Use more instructions so the process runs long enough for frequency sampling.
INSTRUCTIONS = 10_000_000  # 10 million


def sample_cpu_mhz_now():
    """Read MHz of the first core from /proc/cpuinfo."""
    try:
        with open("/proc/cpuinfo") as f:
            for line in f:
                if "cpu MHz" in line:
                    return float(line.split(":")[-1].strip())
    except Exception:
        return None


def get_cpu_max_mhz():
    """Return 'CPU max MHz' from lscpu if available."""
    try:
        out = subprocess.check_output(
            "lscpu | grep -i 'CPU max MHz'", shell=True
        ).decode()
        return float(out.split(":")[-1].strip())
    except Exception:
        return None


def generate_test_file(filename, num_instr):
    print(f"Generating test file with {num_instr:,} instructions ...")
    with open(filename, "w") as f:
        f.write("2" * num_instr)


def run_timed(cmd, measure_freq=False, freq_sample_interval=0.01):
    """Run cmd, return (wall_time_seconds, average_MHz_or_None)."""
    # Start timer and process simultaneously
    start = time.perf_counter()
    proc = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    freq_vals = []
    if measure_freq:
        while proc.poll() is None:
            m = sample_cpu_mhz_now()
            if m is not None:
                freq_vals.append(m)
            time.sleep(freq_sample_interval)
    else:
        proc.wait()

    end = time.perf_counter()
    elapsed = end - start

    avg_freq = statistics.mean(freq_vals) if freq_vals else None
    return elapsed, avg_freq


def main():
    test_file = "benchmark_program.ctf"

    if not os.path.isfile(HARDCORE_BIN):
        print(f"Error: Hardcore binary not found at '{HARDCORE_BIN}'.")
        sys.exit(1)
    if not os.path.isfile(BABY_SCRIPT):
        print(f"Error: Baby script not found at '{BABY_SCRIPT}'.")
        sys.exit(1)

    generate_test_file(test_file, INSTRUCTIONS)

    max_mhz = get_cpu_max_mhz()
    print(f"CPU max MHz: {max_mhz:.0f}" if max_mhz else "CPU max MHz: unknown")
    print(f"\nBenchmarking with {INSTRUCTIONS:,} instructions\n")

    runs = 5

    # --- Hardcore ---
    hardcore_cmd = [HARDCORE_BIN, "-f", test_file]
    print("Hardcore (C++)")
    # warm-up (no freq measurement)
    t, _ = run_timed(hardcore_cmd, measure_freq=False)
    print(f"  warm-up:    {t:.4f}s")
    times_h, freqs_h = [], []
    for i in range(1, runs + 1):
        t, f = run_timed(hardcore_cmd, measure_freq=True)
        times_h.append(t)
        if f:
            freqs_h.append(f)
        print(f"  run {i}/{runs}:    {t:.4f}s", end="")
        if f:
            print(f", avg freq {f:.0f} MHz")
        else:
            print()

    avg_h = sum(times_h) / len(times_h)
    avg_freq_h = statistics.mean(freqs_h) if freqs_h else None

    # --- Baby ---
    baby_cmd = ["python3", BABY_SCRIPT, "-f", test_file]
    print("\nBaby (Python)")
    t, _ = run_timed(baby_cmd, measure_freq=False)
    print(f"  warm-up:    {t:.4f}s")
    times_b, freqs_b = [], []
    for i in range(1, runs + 1):
        t, f = run_timed(baby_cmd, measure_freq=True)
        times_b.append(t)
        if f:
            freqs_b.append(f)
        print(f"  run {i}/{runs}:    {t:.4f}s", end="")
        if f:
            print(f", avg freq {f:.0f} MHz")
        else:
            print()

    avg_b = sum(times_b) / len(times_b)
    avg_freq_b = statistics.mean(freqs_b) if freqs_b else None

    # --- Summary ---
    print(f"\n{'='*50}")
    print(f"Results for {INSTRUCTIONS:,} instructions")
    print(f"Hardcore (C++) :  {avg_h:.4f}s", end="")
    if avg_freq_h:
        print(f"  (avg freq {avg_freq_h:.0f} MHz)")
    else:
        print()
    print(f"Baby (Python)  :  {avg_b:.4f}s", end="")
    if avg_freq_b:
        print(f"  (avg freq {avg_freq_b:.0f} MHz)")
    else:
        print()
    speedup = avg_b / avg_h if avg_h > 0 else float("inf")
    print(f"Speedup:          {speedup:.1f}x")

    if avg_freq_h:
        hz = avg_freq_h * 1e6
        digits_per_s = INSTRUCTIONS / avg_h
        cycles_per_digit = hz / digits_per_s if digits_per_s else 0
        print(
            f"Hardcore: {digits_per_s:,.0f} digits/s  ≈ {cycles_per_digit:.1f} cycles/digit"
        )
    if avg_freq_b:
        hz = avg_freq_b * 1e6
        digits_per_s = INSTRUCTIONS / avg_b
        cycles_per_digit = hz / digits_per_s if digits_per_s else 0
        print(
            f"Baby:     {digits_per_s:,.0f} digits/s  ≈ {cycles_per_digit:.1f} cycles/digit"
        )

    os.remove(test_file)


if __name__ == "__main__":
    main()
