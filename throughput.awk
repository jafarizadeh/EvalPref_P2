

BEGIN {
  if (t0 == "") t0 = 10
  if (t1 == "") t1 = 50
  if (maxfid == "") maxfid = 6

  if (recv == "") recv = "5,6,7"

  n = split(recv, arr, ",")
  for (i = 1; i <= n; i++) {
    recvNode[arr[i]] = 1
  }
}

{
  ev    = $1
  time  = $2
  to    = $4
  ptype = $5
  size  = $6
  fid   = $8


  if (ev == "r" && ptype == "tcp" && size > 40 && time >= t0 && time <= t1) {
    if (to in recvNode) {
      bytes[fid] += size
    }
  }
}

END {
  dur = (t1 - t0)
  if (dur <= 0) {
    print "Error: duration <= 0. Check t0 and t1."
    exit 1
  }

  print "Interval:", t0, "to", t1, "seconds (dur =", dur, ")"
  print "Receivers:", recv
  print "--------------------------------------"

  for (f = 1; f <= maxfid; f++) {
    b = bytes[f] + 0
    mbps = (b * 8.0) / (dur * 1000000.0)
    printf("Flow fid=%d : %.3f Mbps\n", f, mbps)
  }
}
