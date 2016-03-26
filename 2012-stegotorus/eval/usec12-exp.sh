#!/bin/bash
# run one experiment for Usenix Security 2012 paper

################################################################################
# variables with default values

declare -i TOR_TIMEOUT=30
declare OUTPUT_DIR=.
declare PREFIX=""
declare -i MODE=2
declare BRIDGE_IP=87.73.82.145
declare BRIDGE_PORT=8080
declare -i TIMEOUT_STEP_DURATION=10
declare -i TIMEOUT_STEP_N=50

################################################################################
# helper functions:

usage ()  # print error message if given as argument and then general usage
{
    if [ $# -gt 0 ]; then
	echo " *** ERROR: $1"
    fi
    cat << EOF

usage: $0 <OPTIONS> <GENERATE ARGUMENTS>

Monkey script to visit web sites and capturing traffic while using Tor and StegoTorus.
See $DIR/generate-iMacro.sh -h for more info on <GENERATE ARGUMENTS>.

OPTIONS:
   -h                Show this message
   -d <DIR>          Directory root for output (default: ${OUTPUT_DIR})
   -p <PREFIX>       Prefix for all output files (default: ${PREFIX})
   -m <MODE>         Mode to run experiment (default: ${MODE}):
                     1 - just browse web without Tor
                     2 - vanilla Tor with bridge
                     3 - StegoTorus
                     4 - obfsproxy (not yet implemented)
   -t <SEC>          Timeout for Tor circuit to establish (default: ${TOR_TIMEOUT}s)
   -b <IP>[:<PORT>]  Bridge IP and (optional) port (default: ${BRIDGE_IP}:${BRIDGE_PORT})
EOF
}

killFF()  # killing any open Firefoxes and cleaning up a bit
{
    echo "Killing all Firefoxes..."
    killall -q firefox
    if [ $? ]; then  # at least one process was found to be killed
	sleep 1
	find $HOME/.mozilla/firefox -name .parentlock -exec rm -vf {} \; # remove lock files
	find $HOME/.mozilla/firefox -name "sessionstore.*" -exec rm -vf {} \; # remove session store files
    fi
}

cleanUp()  # cleaning up and exiting if argument is given
{
    echo "Stopping packet capture"
    echo "defiance" | sudo -S killall tshark
    echo "Cleaning up..."
    if [ -n "$TOR_PID" ]; then
	echo "Killing Tor"
	kill $TOR_PID
    fi
    if [ -n "$STEGO_PID" ]; then
	echo "Killing StegoTorus client"
	kill $STEGO_PID
    fi
    if [ $# -gt 0 ]; then  # spare the .out file for forensic analysis
	BASE=$(basename $EXPPREFIX)
	find $(dirname $EXPPREFIX) -name "${BASE}*" -and -not -name "*.out" -exec rm -fv {} \;
	exit $1
    fi
}

startAndWaitForTor()  # start Tor and wait until Tor circuit established
                      # 1st argument is bridge address; 2nd argument (if given) is socks4a proxy address
                      # 3rd argument present means to try this many times due to stegotorus
{
    TOR_PID=

    # create .torrc file (if not 2nd try for steogtorus...)
    if [[ $# -lt 3 || $# -gt 2 && $3 -eq 0 ]]; then
	cat > $EXPPREFIX.torrc << EOF
SocksPort 9060 # what port to open for local application connections
SocksListenAddress 127.0.0.1 # accept connections only from localhost

SafeLogging 0
Log info file $EXPPREFIX-tor-info.log

ExitNodes {us}
StrictExitNodes 1

Bridge $1
UseBridges 1
EOF
	if [ $# -gt 1 ]; then
	    cat >> $EXPPREFIX.torrc << EOF

Socks4Proxy $2
EOF
	fi
    fi

    # timer process (in background)
    sleep $TOR_TIMEOUT &
    TIMER_PID=$!
    
    # start the process to look at log output; kill timer when Tor established (run in background)
    STARTED=0
    touch $EXPPREFIX-tor-info.log
    (
	tail -n0 --pid=$TIMER_PID -F $EXPPREFIX-tor-info.log | while read LINE; do 
	    echo $LINE | grep "Bootstrapped 0%" &> /dev/null
	    if [[ $? -eq 0 && $STARTED == 0 ]] ; then
		STARTED=1
		echo "Tor has started"
	    fi
	    echo $LINE | grep "Bootstrapped 100%" &> /dev/null
	    if [[ $? -eq 0 && $STARTED == 1 ]] ; then
		echo "Tor circuit established"
		kill $TIMER_PID  # timer not needed anymore
		break
	    fi
	done
    ) 2> /dev/null &
    
    # start Tor in background
    if [[ $# -gt 2 ]]; then
	TRIAL=$(($3 + 1))
	echo "Starting Tor with timeout=${TOR_TIMEOUT}s (${TRIAL}. trial)..."
    else
	echo "Starting Tor with timeout=${TOR_TIMEOUT}s..."
    fi
    tor -f $EXPPREFIX.torrc &> /dev/null &
    TOR_PID=$!
    
    # wait silently for timer to expire (or be killed)
    if wait %sleep 2> /dev/null; then
	if [[ $# -gt 2 && $3 -lt 5 ]]; then
	    echo "Tor didn't start within timeout of ${TOR_TIMEOUT}s but trying again because of StegoTorus"
	    kill $TOR_PID
	    sleep 3
	    startAndWaitForTor $1 $2 $(($3 + 1))
	else
	    echo "Tor didn't start within timeout of ${TOR_TIMEOUT}s so exiting"
	    #killall tail  # tail on Mac OS X does not support the handy --pid option, so we have to be rough here
	    cleanUp 2
	fi
    else
	echo "Tor is up"
    fi
}

startStegoTorus() 
{
    # timer process (in background)
    STEGO_TIMEOUT=5
    sleep $STEGO_TIMEOUT &
    STEGO_TIMER_PID=$!

    STEGO_PID=
    touch $EXPPREFIX-stego.client &
    (
	tail -n0 --pid=$STEGO_TIMER_PID -F $EXPPREFIX-stego.client | while read LINE; do 
	    echo $LINE | egrep "stegotorus process [0-9]{1,} now initialized" &> /dev/null
	    if [[ $? -eq 0 ]] ; then
		echo "StegoTorus process initialized"
		kill $STEGO_TIMER_PID  # timer not needed anymore
		echo $LINE
		break
	    fi
	done
    ) 2> /dev/null &

    echo "Starting StegoTorus client..."  #TODO: make not absolute path
    CURR_DIR=`pwd`
    # TODO: move this inside the background subshell...
    cd /home/alice/src/stegotorus
    (
	./stegotorus chop socks 127.0.0.1:1080 $BRIDGE_IP:8080 http $BRIDGE_IP:8080 http &> $EXPPREFIX-stego.client
    ) &
    STEGO_PID=$!
    cd $CURR_DIR

    # wait silently for timer to expire (or be killed)
    if wait %sleep 2> /dev/null; then
	echo "StegoTorus didn't start within timeout of ${STEGO_TIMEOUT}s so exiting"
	cleanUp 5
    else
	echo "StegoTorus client is up with PID=$STEGO_PID"
    fi
}

startCapture()  
{
    if [ -z "$IFACE" ]; then
	echo "Cannot start packet capture if interface is empty"
	cleanUp 6
    fi
    echo "Starting packet capture for all packets to and from $BRIDGE_IP"
    echo "defiance" | sudo -S tshark -i $IFACE -a duration:$((TIMEOUT + 30)) -s 0 -f "src or dst $BRIDGE_IP" -w $EXPPREFIX.pcap -q &> /dev/null &
    sleep 2
}

################################################################################
# parse command line:

CMDLINE=`echo $0 $@` # save for output later
DIR=`dirname $0`

while getopts “hd:p:m:t:b:” OPTION
do
    case $OPTION in
        h|\?)
            usage; exit 1
            ;;
	d)
	    OUTPUT_DIR=$OPTARG
	    ;;
	p)
	    PREFIX=$OPTARG
	    ;;
	m)
	    MODE=$OPTARG
	    ;;
	t)
	    TOR_TIMEOUT=$OPTARG
	    ;;
	b)
	    arr=(${OPTARG//:/ })
	    BRIDGE_IP=${arr[0]}
	    if [ ${#arr[@]} -gt 1 ]; then
		BRIDGE_PORT=${arr[1]}
	    fi
	    ;;
    esac
    shift $((OPTIND-1)); OPTIND=1 
done

# test output directory
if [ -z "$OUTPUT_DIR" ]; then
    usage "Output directory not given or empty"; exit 1
fi

# valid mode?
if [ "$MODE" -lt 2 ] || [ "$MODE" -gt 3 ]; then
    usage "Given mode is not between [2..3]"; exit 1
fi

# calc overall timout:
TIMEOUT=$((TIMEOUT_STEP_DURATION*TIMEOUT_STEP_N*MODE))

# create experiment prefix: 
EXPPREFIX=$(printf %s/%s/m%d/%s%s $OUTPUT_DIR $2 $MODE $PREFIX $(date +"%Y-%m-%d-%H-%M-%ST%z"))
mkdir -p $(dirname $EXPPREFIX)
echo "Filing run under prefix $EXPPREFIX"

################################################################################
# create iMacro for browsing web with timeout = $MODE*100
$DIR/generate-iMacro.sh -t $((TIMEOUT - 60)) $(dirname $EXPPREFIX) $(basename $EXPPREFIX) $@
if [ $? -gt 0 ]; then
    usage "Couldn't generate iMacro -- exiting"; cleanUp 1
fi

killFF # kill any open firefoxes

################################################################################
# create summary file with versions
echo "$CMDLINE" > $EXPPREFIX.out
tshark -version | head -n 1 >> $EXPPREFIX.out
echo >> $EXPPREFIX.out
tor --version >> $EXPPREFIX.out
echo >> $EXPPREFIX.out

################################################################################
# obtain IPv4 address of eth0 or eth1 and start packet capture
# TODO: if using mode 1, different filter needed
INET_ADDR=
IFACE=
i=0
while [[ -z "$INET_ADDR" && $i -lt 4 ]]; do
    IFACE=$(printf eth%d $i)
    INET_ADDR=`ifconfig $IFACE | grep "inet " | sed "s/[^\.0-9 ]//g" | sed "s/^[ \t]*//" | cut -d' ' -f1`
    i=$((i+1))
done
if [ -z "$INET_ADDR" ]; then
    usage "Couldn't find external IP address -- exiting"; cleanUp 1
fi

################################################################################
# start Tor, then packet capture and then firefox with specific profile
case $MODE in
    1)
	firefox -P "no-tor" -width 800 -height 600 &> /dev/null &
	;;
    2)
	startAndWaitForTor $BRIDGE_IP:$BRIDGE_PORT
	startCapture
	firefox -P "with-tor" &> /dev/null &
	;;
    3)
	# start stegotorus client; assuming server is running on default port 8080 started with:
	#                          $> ./stegotorus chop server 127.0.0.1:8888 128.18.9.71:8080
	startStegoTorus
	# start tor with socks proxy setting and up to 4 tries
	startAndWaitForTor $BRIDGE_IP:$BRIDGE_PORT 127.0.0.1:1080 0
	startCapture
	firefox -P "with-tor" &> /dev/null &
	;;
esac
sleep 5 # give firefox a chance to start up

################################################################################
# load web site
# run iMacro with timeout in case macro poops out:
rm -f $(dirname $EXPPREFIX)/last_screenshot.png
printf "\nRunning iMacro with timeout=%ds at %s\n" $TIMEOUT `date +%s.%N` >> $EXPPREFIX.out
printf "Running iMacro with timeout=%ds" $TIMEOUT
firefox -new-tab "http://run.imacros.net/?m=temp.iim" &> /dev/null
while [[ ! -e $(dirname $EXPPREFIX)/last_screenshot.png && $TIMEOUT_STEP_N -gt 0 ]]; do
    printf "."
    TIMEOUT_STEP_N=$((TIMEOUT_STEP_N - 1))
    sleep $((TIMEOUT_STEP_DURATION*MODE))
done
echo "done"

################################################################################
# clean up (which stops Tor and pcap)

killFF
if [ -s $(dirname $EXPPREFIX)/last_screenshot.png ]; then
    echo " ~~~ Run was successful ~~~"
    # keep track of last screen shot and script that was used
    mv -v $(dirname $EXPPREFIX)/last_screenshot.png $EXPPREFIX-last-screenshot.png
    cp -pv $1/temp.iim $EXPPREFIX.iim
else
    echo " ~~~ Run was not successful ~~~"
    cleanUp 4
fi
cleanUp