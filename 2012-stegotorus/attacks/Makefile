all : flowstat flowfind

flowstat : flowstat.cc
	g++ flowstat.cc -I/usr/include/pcap -lpcap -o flowstat

flowfind : flowfind.cc
	g++ flowfind.cc -I/usr/include/pcap -lpcap -o flowfind

clean :
	rm flowstat flowfind
