import argparse
from collections import defaultdict
import matplotlib.pyplot as plt


def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--trace", required=True, help="NS-2 trace (e.g. p13_mix.tr)")
    p.add_argument("--qmon", required=True, help="Queue monitor file (e.g. p13_mix_qmon.tr)")
    p.add_argument("--t0", type=float, default=20.0)
    p.add_argument("--t1", type=float, default=180.0)
    p.add_argument("--bin", type=float, default=1.0, help="time bin (s)")
    p.add_argument("--r0", type=str, default="0")
    p.add_argument("--r1", type=str, default="1")
    p.add_argument("--out_prefix", default="p13")
    return p.parse_args()


def load_qmon(qmon_path):
    t = []
    q = []
    with open(qmon_path, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            parts = line.split()
            # monitor-queue output usually starts with: time qlen ...
            try:
                tt = float(parts[0])
                qq = float(parts[1])
            except Exception:
                continue
            t.append(tt)
            q.append(qq)
    return t, q


def link_utilisation(trace_path, t0, t1, bin_s, r0, r1):
    bits_in_bin = defaultdict(int)

    with open(trace_path, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            parts = line.split()
            if len(parts) < 6:
                continue
            ev = parts[0]
            try:
                time = float(parts[1])
            except ValueError:
                continue
            if time < t0 or time > t1:
                continue

            fr = parts[2]
            to = parts[3]
            ptype = parts[4]
            try:
                size = int(parts[5])
            except ValueError:
                continue

            # count packets received on the core link (r0 -> r1)
            if ev == "r" and fr == r0 and to == r1 and ptype in ("tcp", "ack"):
                b = int((time - t0) // bin_s)
                bits_in_bin[b] += size * 8

    xs = []
    ys = []
    nbins = int((t1 - t0) // bin_s) + 1
    for b in range(nbins):
        xs.append(t0 + b * bin_s)
        ys.append(bits_in_bin[b] / bin_s / 1_000_000.0)  # Mbps
    return xs, ys


def main():
    args = parse_args()

    tq, qq = load_qmon(args.qmon)
    x, y = link_utilisation(args.trace, args.t0, args.t1, args.bin, args.r0, args.r1)

    plt.figure()
    plt.plot(tq, qq)
    plt.xlabel("Time (s)")
    plt.ylabel("Queue length (packets)")
    plt.title("Bottleneck queue length vs time")
    plt.tight_layout()
    plt.savefig(f"{args.out_prefix}_queue.png", dpi=200)

    plt.figure()
    plt.plot(x, y)
    plt.xlabel("Time (s)")
    plt.ylabel("Core link rate (Mbps)")
    plt.title("Bottleneck load vs time (from trace)")
    plt.tight_layout()
    plt.savefig(f"{args.out_prefix}_load.png", dpi=200)

    print("Saved:", f"{args.out_prefix}_queue.png", "and", f"{args.out_prefix}_load.png")


if __name__ == "__main__":
    main()
