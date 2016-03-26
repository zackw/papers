README for evaluation scripts
=============================

Purpose
-------

purpose: collect traces and apply Tor fingerprinting attacks against them for evaluation section

3 modes; mode 2) and 3) are the interesting ones and mode 1) currently not supported
 mode 1) 
   Alice browser --> | pcap | --> web
 mode 2) 
   Alice browser --> Alice Tor client --> | pcap | --> vm06 Tor Bridge --> Tor circuit & web
 mode 3)
   Alice browser --> Alice Tor client --> Alice Stego client --> | pcap | --> vm06 Stego server --> vm06 Tor Bridge --> Tor circuit & web

expected outcome:
 mode	| Tor fingerprinting
 -----------------------------------
 1    	| negative
 2    	| positive
 3    	| negative

Requirements
------------

on host:
  - VirtualBox 4.1.8 with guest additions (for shared folders and scripting)

on Ubuntu guest:
  - currently using /media/sf_shared as shared folder for script input and output but problems with host-driven scripts (see below)
  - Firefox with 2 profiles "no-tor" and "with-tor", the latter using proxy at 127.0.0.1:9060 to connect to Internet
  - iMacros for Firefox 7.4.0.8 with directories configured to /media/sf_shared/iMacros in both Firefox profiles
  - user "alice" with password "defiance" and sudoer
  - tshark 1.6.4 for packet capture (or tcpdump)
  - tor v0.2.2.35
  - stegotorus (currently hardcoded under /home/alice/src/stegotorus)

Scripts
-------

  GUEST SCRIPTS

the main script to perform a run with capturing packets on a machine posing as Alice is called "usec12-exp.sh".  It uses iMacros for Firefox to load a web page from the Top 10 Sites as listed on alexa.com.  These top sites are saved in the file "alexa.txt" and the iMacro is generated from the script "generate-iMacro.sh"

detailed flow:
 - restore Alice VM to snapshot & start VM
 - (mode 3 only) start Stego client
 - start Tor client and wait for "Bootstrapped 100%" log output
 - start packet capture: -s 0 -f "src or dst $vm06_ip"
 - run iMacro
 - stop packet capture
 - stop Tor client
 - (mode 3 only) stop Stego client

examples (note difference of bridge port for mode 2 and 3!)

"visit 1st Alexa site in mode 2 giving Tor a timeout of 30 sec to start"
  ./usec12-exp.sh -m 2 -t 30 -d `pwd` -b 128.18.9.71:8888 /media/sf_shared/iMacros/Macros alexa 1

"visit 3rd Alexa site in mode 3 giving Tor a timeout of 3 min to start"
  ./usec12-exp.sh -m 3 -t 180 -d `pwd` -b 128.18.9.71:8080 /media/sf_shared/iMacros/Macros alexa 3


  HOST SCRIPTS

started a script called "run-exps.sh" that outlines looping through various configurations from the host and restarting a fresh VM every time.  However, currently having problems with mounting the shared folders for data transfer.  If we don't have a shared folder mounted, not sure how to preserve the captured data.  It seems that the auto-mounting (or manual mounting) is happening too early in the script.  I used "testShared.sh" for testing this.
