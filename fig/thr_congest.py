# plot_throughput.py
# Simple plot for Part 1.2: throughput per flow (fid=1..6)
#
# Usage examples:
#   python3 plot_throughput.py p12_congest.tr --t0 20 --t1 180 --out thr_congest.png
#   python3 plot_throughput.py p12_nocongest.tr --t0 10 --t1 50  --out thr_nocongest.png
#
# Notes:
# - This script assumes the "old" NS-2 trace format:
#   event time from to type size flags fid src dst seq id
# - It counts only received TCP data-like packets at receivers (node IDs 5,6,7)
# - It ignores small packets (size<=40) to avoid counting pure ACKs

import argparse
from collections import defaultdict
import matplotlib.pyplot as plt


def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("trace", help="NS-2 trace file (e.g., p12_congest.tr)")
    p.add_argument("--t0", type=float, default=10.0, help="start time for measurement")
    p.add_argument("--t1", type=float, default=50.0, help="end time for measurement")
    p.add_argument("--receivers", default="5,6,7", help="receiver node IDs, comma-separated")
    p.add_argument("--maxfid", type=int, default=6, help="number of flows (fids from 1..maxfid)")
    p.add_argument("--out", default="throughput.png", help="output image file (png)")
    return p.parse_args()


def compute_throughput_mbps(trace_path, t0, t1, receivers_set, maxfid):
    bytes_by_fid = defaultdict(int)

    with open(trace_path, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue

            parts = line.split()
            # Need at least 8 fields to read ev,time,to,type,size,fid
            if len(parts) < 8:
                continue

            ev = parts[0]
            try:
                time = float(parts[1])
            except ValueError:
                continue

            # Only within measurement window
            if time < t0 or time > t1:
                continue

            # Old trace indices:
            # 0 event, 1 time, 2 from, 3 to, 4 type, 5 size, 6 flags, 7 fid, ...
            to_node = parts[3]
            ptype = parts[4]

            try:
                size = int(parts[5])
            except ValueError:
                continue

            try:
                fid = int(parts[7])
            except ValueError:
                continue

            # Count only received TCP data-like packets at receivers
            if ev == "r" and ptype == "tcp" and size > 40 and to_node in receivers_set:
                if 1 <= fid <= maxfid:
                    bytes_by_fid[fid] += size

    dur = t1 - t0
    if dur <= 0:
        raise ValueError("t1 must be > t0")

    thr = []
    for fid in range(1, maxfid + 1):
        b = bytes_by_fid.get(fid, 0)
        mbps = (b * 8.0) / (dur * 1_000_000.0)
        thr.append(mbps)

    return thr


def main():
    args = parse_args()
    receivers_set = {x.strip() for x in args.receivers.split(",") if x.strip()}

    thr = compute_throughput_mbps(
        args.trace, args.t0, args.t1, receivers_set, args.maxfid
    )

    # Simple bar chart
    fids = list(range(1, args.maxfid + 1))
    plt.figure()
    plt.bar(fids, thr)
    plt.xlabel("Flow id (fid)")
    plt.ylabel("Average throughput (Mbps)")
    plt.title(f"Throughput per flow\n{args.trace}   [{args.t0}, {args.t1}] s")
    plt.xticks(fids)

    plt.tight_layout()
    plt.savefig(args.out, dpi=200)
    print("Saved:", args.out)

    # Also print values (useful for copy/paste into the report table)
    for fid, mbps in zip(fids, thr):
        print(f"fid={fid}  throughput={mbps:.3f} Mbps")


if __name__ == "__main__":
    main()
