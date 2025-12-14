# Usage:
#   gawk -f throughput.awk -v t0=20 -v t1=180 p12_congest.tr
#   gawk -f throughput.awk -v t0=20 -v t1=180 p12_nocongest.tr

BEGIN {
  if (t0 == "") t0 = 20
  if (t1 == "") t1 = 180
}

# NS-2 trace (old format):
# event time from to type size flags fid src dst seq id
{
  ev   = $1
  time = $2
  to   = $4
  ptype= $5
  size = $6
  fid  = $8

  # Count only received TCP data packets at receivers (nodes 5,6,7)
  if (ev == "r" && ptype == "tcp" && time >= t0 && time <= t1) {
    if (to == 5 || to == 6 || to == 7) {
      bytes[fid] += size
    }
  }
}

END {
  dur = (t1 - t0)
  print "Interval:", t0, "to", t1, "seconds (dur=", dur, ")"
  for (f = 1; f <= 6; f++) {
    mbps = (bytes[f] * 8.0) / (dur * 1000000.0)
    printf("Flow fid=%d : %.3f Mbps\n", f, mbps)
  }
}
