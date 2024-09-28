"""Python port of test_tdc_carry4_original.m: decode raw TDC measurement
frames and compute per-file statistics.

Frame format (5 hex tokens per measurement, as exported by the FPGA debug
core): [x, stop_count, stop_phase, trig_count, trig_phase]. Phase values are
1..50 delay bins of BIN_PS; 0 wraps to 50. Coarse counts are 8-bit and wrap
(checked via trig_count > stop_count).

    delay_ps = (stop_count - trig_count) * COARSE_BINS * BIN_PS
             + (trig_phase - stop_phase) * BIN_PS

Single-shot precision = std(delay)/sqrt(2) over the ~4.5-5k measurements of
one fixed input interval (the sqrt(2) follows the original script: two
independent edge-timing contributions).
"""
import argparse
import csv
import glob
import os

import numpy as np

BIN_PS = 72
COARSE_BINS = 50


def parse_file(path):
    toks = open(path, errors="ignore").read().split()
    b = []
    for t in toks:
        if len(t) == 2 and t[0] != ".":
            b.append(int(t, 16))
    n = len(b) // 5
    b = np.asarray(b[: n * 5], dtype=np.int64).reshape(n, 5)
    stop_c, stop_p, trig_c, trig_p = b[:, 1], b[:, 2], b[:, 3], b[:, 4]
    stop_p = np.where(stop_p == 0, COARSE_BINS, stop_p)
    trig_p = np.where(trig_p == 0, COARSE_BINS, trig_p)
    stop_c = np.where(trig_c > stop_c, stop_c + 256, stop_c)  # 8-bit wrap
    delay = (stop_c - trig_c) * COARSE_BINS * BIN_PS + (trig_p - stop_p) * BIN_PS
    return delay.astype(float)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--data-dir", default=os.path.join(os.path.dirname(__file__), "measurement_data"))
    ap.add_argument("--out-dir", default=os.path.join(os.path.dirname(__file__), "..", "results"))
    args = ap.parse_args()
    os.makedirs(args.out_dir, exist_ok=True)

    files = sorted(glob.glob(os.path.join(args.data_dir, "*.txt")))
    rows, delays = [], {}
    for fp in files:
        d = parse_file(fp)
        if len(d) < 100:
            continue
        delays[os.path.basename(fp)] = d
        rows.append((os.path.basename(fp), len(d), d.mean(), d.std(ddof=0) / np.sqrt(2)))

    precisions = np.array([r[3] for r in rows])
    with open(os.path.join(args.out_dir, "precision_table.csv"), "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["file", "n_measurements", "mean_interval_ps", "single_shot_precision_ps"])
        w.writerows([[r[0], r[1], round(r[2], 1), round(r[3], 2)] for r in rows])
        w.writerow(["median", "", "", round(float(np.median(precisions)), 2)])
        w.writerow(["mean", "", "", round(float(precisions.mean()), 2)])

    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    # precision vs input interval (files are 100 ps steps)
    fig, ax = plt.subplots(figsize=(5.4, 3.2))
    xs = np.arange(len(rows))
    ax.errorbar(xs, [r[2] for r in rows], yerr=precisions, fmt="o-", ms=3,
                capsize=2, lw=1, label="measured interval ± precision")
    ax2 = ax.twinx()
    ax2.plot(xs, precisions, "s--", c="tab:red", ms=3, label="single-shot precision")
    ax2.set_ylabel("precision [ps]", color="tab:red")
    ax.set_ylabel("mean interval [ps]")
    ax.set_xlabel("test file index (nominal 100 ps steps)")
    ax.grid(alpha=.3)
    fig.tight_layout()
    fig.savefig(os.path.join(args.out_dir, "interval_tracking.png"), dpi=160)

    rep = rows[len(rows) // 2][0]
    fig, ax = plt.subplots(figsize=(5.4, 3.2))
    ax.hist(delays[rep], bins=40)
    ax.set_xlabel(f"measured interval [ps] ({rep})")
    ax.set_ylabel("count")
    fig.tight_layout()
    fig.savefig(os.path.join(args.out_dir, "delay_histogram.png"), dpi=160)

    print(f"files: {len(rows)}")
    print(f"single-shot precision (std/sqrt(2)) -> median {np.median(precisions):.2f} ps, "
          f"mean {precisions.mean():.2f} ps, range {precisions.min():.2f}-{precisions.max():.2f} ps")
    print(f"bin width (LSB): {BIN_PS} ps | coarse unit: {COARSE_BINS} bins = {COARSE_BINS * BIN_PS / 1000:.1f} ns")
    print(f"written: {args.out_dir}")


if __name__ == "__main__":
    main()
