#!/usr/bin/env python3
"""speedmotor_with_freq.py – benchmarks CTFFuck2 interpreters + live CPU frequency"""

import subprocess
import time
import sys
import os
import statistics

HARDCORE_BIN = "./build/ctffuck2-hardcore"
BABY_SCRIPT = "baby-ctffuck2.py"


def get_cpu_max_mhz():
    """Return max CPU frequency in MHz (from lscpu)."""
    try:
        out = subprocess.check_output(
            "lscpu | grep -i 'CPU max MHz'", shell=True
        ).decode()
        return float(out.split(":")[-1].strip())
    except Exception:
        return None


def sample_cpu_mhz_now():
    """Return current CPU MHz from /proc/cpuinfo (first core)."""
    try:
        with open("/proc/cpuinfo") as f:
            for line in f:
                if "cpu MHz" in line:
                    return float(line.split(":")[-1].strip())
    except Exception:
        return None
    return None


def sample_cpu_mhz_average(duration=0.5, samples=10):
    """Average MHz over 'samples' readings across 'duration' seconds."""
    readings = []
    interval = duration / samples
    for _ in range(samples):
        m = sample_cpu_mhz_now()
        if m:
            readings.append(m)
        time.sleep(interval)
    if readings:
        return statistics.mean(readings)
    return None


def generate_test_file(filename, num_instr=1_000_000):
    print(f"Generating test program with {num_instr:,} instructions...")
    with open(filename, "w") as f:
        f.write("2" * num_instr)


def run_and_measure(cmd, description, measure_freq=False):
    """Run command, measure wall time, optionally log frequency during run."""
    print(f"  Running: {description}...", end="", flush=True)

    # Start command in background so we can sample MHz while it runs
    proc = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    freq_samples = []
    if measure_freq:
        # Sample while process is alive
        while proc.poll() is None:
            m = sample_cpu_mhz_now()
            if m:
                freq_samples.append(m)
            time.sleep(0.05)  # sample every 50ms
    else:
        proc.wait()

    start = time.perf_counter()
    proc.wait()
    end = time.perf_counter()
    elapsed = end - start

    status = "OK" if proc.returncode == 0 else f"FAIL (rc={proc.returncode})"
    print(f" {elapsed:.3f}s ({status})", end="")
    avg_freq = statistics.mean(freq_samples) if freq_samples else None
    if avg_freq:
        print(f", avg freq: {avg_freq:.0f} MHz", end="")
    print()
    return elapsed, avg_freq


def main():
    test_file = "benchmark_program.ctf"
    instructions = 1_000_000
    runs = 5

    # Check executables
    if not os.path.isfile(HARDCORE_BIN):
        print(
            f"Error: Hardcore binary not found at '{HARDCORE_BIN}'. Build it first (./build.sh)."
        )
        sys.exit(1)
    if not os.path.isfile(BABY_SCRIPT):
        print(f"Error: Baby script not found at '{BABY_SCRIPT}'.")
        sys.exit(1)

    generate_test_file(test_file, instructions)

    max_mhz = get_cpu_max_mhz()
    if max_mhz:
        print(f"CPU max MHz (from lscpu): {max_mhz:.1f}\n")
    else:
        print("(Could not read max CPU MHz)\n")

    print("=========== Benchmarks ===========")

    # --- Hardcore ---
    hardcore_cmd = [HARDCORE_BIN, "-f", test_file]
    # warm-up
    run_and_measure(hardcore_cmd, "Hardcore warm-up", measure_freq=False)
    times_h, freqs_h = [], []
    for i in range(runs):
        t, f = run_and_measure(
            hardcore_cmd, f"Hardcore run {i+1}/{runs}", measure_freq=True
        )
        times_h.append(t)
        if f:
            freqs_h.append(f)
    avg_h = sum(times_h) / len(times_h)
    avg_freq_h = statistics.mean(freqs_h) if freqs_h else None

    # --- Baby ---
    baby_cmd = ["python3", BABY_SCRIPT, "-f", test_file]
    run_and_measure(baby_cmd, "Baby warm-up", measure_freq=False)
    times_b, freqs_b = [], []
    for i in range(runs):
        t, f = run_and_measure(baby_cmd, f"Baby run {i+1}/{runs}", measure_freq=True)
        times_b.append(t)
        if f:
            freqs_b.append(f)
    avg_b = sum(times_b) / len(times_b)
    avg_freq_b = statistics.mean(freqs_b) if freqs_b else None

    # --- Summary ---
    print(f"\n=========== Summary for {instructions:,} instructions ===========")
    print(f"Hardcore (C++): {avg_h:.3f} s", end="")
    if avg_freq_h:
        print(f", avg CPU freq: {avg_freq_h:.0f} MHz", end="")
    print()
    print(f"Baby (Python):  {avg_b:.3f} s", end="")
    if avg_freq_b:
        print(f", avg CPU freq: {avg_freq_b:.0f} MHz", end="")
    print()
    speedup = avg_b / avg_h if avg_h > 0 else float("inf")
    print(f"Speedup:        {speedup:.1f}x")

    # Cycles per digit estimate
    if avg_freq_h and avg_h > 0:
        hz = avg_freq_h * 1e6
        digits_per_s = instructions / avg_h
        cycles_per_digit = hz / digits_per_s if digits_per_s else 0
        print(
            f"Hardcore: {digits_per_s:,.0f} digits/s, ~{cycles_per_digit:.1f} cycles/digit"
        )

    if avg_freq_b and avg_b > 0:
        hz = avg_freq_b * 1e6
        digits_per_s = instructions / avg_b
        cycles_per_digit = hz / digits_per_s if digits_per_s else 0
        print(
            f"Baby:     {digits_per_s:,.0f} digits/s, ~{cycles_per_digit:.1f} cycles/digit"
        )

    os.remove(test_file)


if __name__ == "__main__":
    main()
