# -------------------------------------------------
# EvalPerf - Part 1.1 (NS-2 TCL)
# Topology: 8 nodes, one bottleneck core link
# 6 TCP/FTP flows, different RTTs using different access delays
# -------------------------------------------------

set ns [new Simulator]

# Trace files
set tr [open out.tr w]
$ns trace-all $tr

set nf [open out.nam w]
$ns namtrace-all $nf

# Finish procedure
proc finish {} {
    global ns tr nf
    $ns flush-trace
    close $tr
    close $nf
    puts "Done. Files: out.tr and out.nam"
    exit 0
}

# -------------------------------------------------
# Create nodes (8 nodes)
# r0, r1 are the two core routers
# s0,s1,s2 are senders; d0,d1,d2 are receivers
# -------------------------------------------------
set r0 [$ns node]
set r1 [$ns node]

set s0 [$ns node]
set s1 [$ns node]
set s2 [$ns node]

set d0 [$ns node]
set d1 [$ns node]
set d2 [$ns node]

# -------------------------------------------------
# Links
# Access links are fast (100Mb), but with different delays -> different RTTs
# Core link (r0-r1) is the bottleneck (10Mb)
# -------------------------------------------------

# Sender side (different delays)
$ns duplex-link $s0 $r0 100Mb 5ms  DropTail
$ns duplex-link $s1 $r0 100Mb 25ms DropTail
$ns duplex-link $s2 $r0 100Mb 60ms DropTail

# Receiver side (same pattern to keep it simple)
$ns duplex-link $d0 $r1 100Mb 5ms  DropTail
$ns duplex-link $d1 $r1 100Mb 25ms DropTail
$ns duplex-link $d2 $r1 100Mb 60ms DropTail

# Core bottleneck link
$ns duplex-link $r0 $r1 10Mb 10ms DropTail

# Queue limit on the bottleneck (both directions)
$ns queue-limit $r0 $r1 50
$ns queue-limit $r1 $r0 50

# Optional: small NAM layout hints
$ns duplex-link-op $r0 $r1 orient right
$ns duplex-link-op $s0 $r0 orient right-down
$ns duplex-link-op $s1 $r0 orient right
$ns duplex-link-op $s2 $r0 orient right-up
$ns duplex-link-op $d0 $r1 orient left-down
$ns duplex-link-op $d1 $r1 orient left
$ns duplex-link-op $d2 $r1 orient left-up

# -------------------------------------------------
# Helper: create one FTP over TCP flow
# Arguments: ns, src, dst, flow_id, start_time
# -------------------------------------------------
proc make_ftp_flow {ns src dst fid startTime} {

    set tcp [new Agent/TCP]
    $tcp set fid_ $fid
    $tcp set window_ 1000
    $tcp set maxcwnd_ 1000

    set sink [new Agent/TCPSink]

    $ns attach-agent $src $tcp
    $ns attach-agent $dst $sink
    $ns connect $tcp $sink

    set ftp [new Application/FTP]
    $ftp attach-agent $tcp

    $ns at $startTime "$ftp start"

    return $ftp
}

# -------------------------------------------------
# Create 6 flows
# Two flows for each pair: (s0->d0), (s1->d1), (s2->d2)
# Start times are slightly different to avoid perfect synchronization
# -------------------------------------------------

set f0 [make_ftp_flow $ns $s0 $d0 1 0.5]
set f1 [make_ftp_flow $ns $s0 $d0 2 0.7]

set f2 [make_ftp_flow $ns $s1 $d1 3 1.0]
set f3 [make_ftp_flow $ns $s1 $d1 4 1.2]

set f4 [make_ftp_flow $ns $s2 $d2 5 1.5]
set f5 [make_ftp_flow $ns $s2 $d2 6 1.7]

# End simulation
$ns at 20.0 "finish"
$ns run
