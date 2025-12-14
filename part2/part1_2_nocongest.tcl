

set ns [new Simulator]

set tr [open p12_nocongest.tr w]
$ns trace-all $tr

set nf [open p12_nocongest.nam w]
$ns namtrace-all $nf

set SIMTIME 60.0
set ACCESS_BW "10Mb"
set CORE_BW   "100Mb"
set CORE_DELAY "10ms"
set QLIMIT 200

proc finish {} {
    global ns tr nf
    $ns flush-trace
    close $tr
    close $nf
    puts "Done. Files: p12_nocongest.tr and p12_nocongest.nam"
    exit 0
}

set r0 [$ns node]
set r1 [$ns node]

set s0 [$ns node]
set s1 [$ns node]
set s2 [$ns node]

set d0 [$ns node]
set d1 [$ns node]
set d2 [$ns node]

$ns duplex-link $s0 $r0 $ACCESS_BW 5ms  DropTail
$ns duplex-link $s1 $r0 $ACCESS_BW 25ms DropTail
$ns duplex-link $s2 $r0 $ACCESS_BW 60ms DropTail

$ns duplex-link $d0 $r1 $ACCESS_BW 5ms  DropTail
$ns duplex-link $d1 $r1 $ACCESS_BW 25ms DropTail
$ns duplex-link $d2 $r1 $ACCESS_BW 60ms DropTail

$ns duplex-link $r0 $r1 $CORE_BW $CORE_DELAY DropTail
$ns queue-limit $r0 $r1 $QLIMIT
$ns queue-limit $r1 $r0 $QLIMIT

proc make_ftp_flow {ns src dst fid startTime} {
    set tcp [new Agent/TCP]
    $tcp set fid_ $fid

    $tcp set window_ 5000
    $tcp set maxcwnd_ 5000

    set sink [new Agent/TCPSink]
    $sink set maxwnd_ 5000

    $ns attach-agent $src $tcp
    $ns attach-agent $dst $sink
    $ns connect $tcp $sink

    set ftp [new Application/FTP]
    $ftp attach-agent $tcp
    $ns at $startTime "$ftp start"
    return $ftp
}

set f0 [make_ftp_flow $ns $s0 $d0 1 0.5]
set f1 [make_ftp_flow $ns $s0 $d0 2 0.7]

set f2 [make_ftp_flow $ns $s1 $d1 3 0.9]
set f3 [make_ftp_flow $ns $s1 $d1 4 1.1]

set f4 [make_ftp_flow $ns $s2 $d2 5 1.3]
set f5 [make_ftp_flow $ns $s2 $d2 6 1.5]

$ns at $SIMTIME "finish"
$ns run
