set ns [new Simulator]

set tr [open p13_ref.tr w]
$ns trace-all $tr

set qf [open p13_ref_qmon.tr w]

proc finish {} {
    global ns tr qf
    $ns flush-trace
    close $tr
    close $qf
    puts "Done. p13_ref.tr , p13_ref_qmon.tr"
    exit 0
}

set SIMTIME 200.0

set ACCESS_BW "10Mb"
set ACCESS_DLY "20ms"

set CORE_BW   "2Mb"
set CORE_DLY  "10ms"
set QLIMIT 30

set r0 [$ns node]
set r1 [$ns node]

set s0 [$ns node]
set s1 [$ns node]
set s2 [$ns node]

set d0 [$ns node]
set d1 [$ns node]
set d2 [$ns node]

$ns duplex-link $s0 $r0 $ACCESS_BW $ACCESS_DLY DropTail
$ns duplex-link $s1 $r0 $ACCESS_BW $ACCESS_DLY DropTail
$ns duplex-link $s2 $r0 $ACCESS_BW $ACCESS_DLY DropTail

$ns duplex-link $d0 $r1 $ACCESS_BW $ACCESS_DLY DropTail
$ns duplex-link $d1 $r1 $ACCESS_BW $ACCESS_DLY DropTail
$ns duplex-link $d2 $r1 $ACCESS_BW $ACCESS_DLY DropTail

$ns duplex-link $r0 $r1 $CORE_BW $CORE_DLY DropTail
$ns queue-limit $r0 $r1 $QLIMIT
$ns queue-limit $r1 $r0 $QLIMIT

set qmon [$ns monitor-queue $r0 $r1 $qf 0.1]

proc make_flow {ns src dst fid tcpClass sinkClass startTime} {
    set tcp [new $tcpClass]
    $tcp set fid_ $fid
    $tcp set window_ 5000
    $tcp set maxcwnd_ 5000

    set sink [new $sinkClass]
    $sink set maxwnd_ 5000

    $ns attach-agent $src $tcp
    $ns attach-agent $dst $sink
    $ns connect $tcp $sink

    set ftp [new Application/FTP]
    $ftp attach-agent $tcp

    $ns at $startTime "$ftp start"
    return $tcp
}

set TCPREF "Agent/TCP/Newreno"
set SINK   "Agent/TCPSink"

set t1 [make_flow $ns $s0 $d0 1 $TCPREF $SINK 0.5]
set t2 [make_flow $ns $s0 $d0 2 $TCPREF $SINK 0.7]
set t3 [make_flow $ns $s1 $d1 3 $TCPREF $SINK 0.9]
set t4 [make_flow $ns $s1 $d1 4 $TCPREF $SINK 1.1]
set t5 [make_flow $ns $s2 $d2 5 $TCPREF $SINK 1.3]
set t6 [make_flow $ns $s2 $d2 6 $TCPREF $SINK 1.5]

$ns at $SIMTIME "finish"
$ns run
