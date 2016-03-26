#include <pcap.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <dirent.h>

#include <iostream>
#include <vector>
#include <cmath>
#include <set>
using namespace std;

#define ETHER_OFFSET 14
#define MAX_WINDOW_SIZE 2048

char errbuf[PCAP_ERRBUF_SIZE];

struct packet {
  bool outgoing;
  u_short size;

  packet(bool outgoing, u_short size) : outgoing(outgoing), size(size) { }
};

int window_size;
double mean_in[MAX_WINDOW_SIZE], stddev_in[MAX_WINDOW_SIZE];
double mean_out[MAX_WINDOW_SIZE], stddev_out[MAX_WINDOW_SIZE];
set<int> seq[2];
vector<vector<packet> > all_pkts;

u_int process_pcap_file(pcap_t *handle) {
  u_int pkt_count = 0;
  vector<packet> pkts;

  pcap_pkthdr header;
  const u_char *pkt_ptr;
  while (pkt_ptr = pcap_next(handle, &header)) {
    ip *ip_pkt = (ip *)(pkt_ptr + ETHER_OFFSET);
    tcphdr *tcp_pkt = (tcphdr *)((u_char *)ip_pkt + 4*ip_pkt->ip_hl);
    u_char *data = (u_char *)((u_char *)tcp_pkt + 4*tcp_pkt->th_off);

    bool outgoing;
    in_addr ip_src = ip_pkt->ip_src;
    unsigned long first_byte = ntohl(ip_src.s_addr) / (1 << 24);
    if (first_byte == 10 || first_byte == 171) {
      // stanford ip
      outgoing = true;
    } else {
      outgoing = false;
    }

    int seqno = ntohl(tcp_pkt->th_seq);
    if (seq[outgoing].find(seqno) != seq[outgoing].end()) continue;
    seq[outgoing].insert(seqno);

    u_short len = ntohs(ip_pkt->ip_len)-sizeof(ip)-sizeof(tcphdr);
    pkts.push_back(packet(outgoing, len));
  }

  all_pkts.push_back(pkts);
  return pkts.size();
}

void compute_avg() {
  cout << window_size << endl;
  vector<int> acc_in(all_pkts.size(), 0), acc_out(all_pkts.size(), 0);
  for (int i = 0; i < window_size; i++) {
    for (int j = 0; j < all_pkts.size(); j++) {
      if (all_pkts[j][i].outgoing) acc_out[j] += all_pkts[j][i].size;
      else acc_in[j] += all_pkts[j][i].size;
    }

    mean_in[i] = mean_out[i] = 0;
    for (int j = 0; j < all_pkts.size(); j++) {
       mean_in[i] += acc_in[j];
       mean_out[i] += acc_out[j];
    }
    mean_in[i] /= all_pkts.size();
    mean_out[i] /= all_pkts.size();

    stddev_in[i] = stddev_out[i] = 0;
    for (int j = 0; j < all_pkts.size(); j++) {
      stddev_in[i] += (acc_in[j]-mean_in[i])*(acc_in[j]-mean_in[i]);
      stddev_out[i] += (acc_out[j]-mean_out[i])*(acc_out[j]-mean_out[i]);
    }
    stddev_in[i] = sqrt(stddev_in[i]/(all_pkts.size()-1));
    stddev_out[i] = sqrt(stddev_out[i]/(all_pkts.size()-1));
    cout << mean_in[i] << " " << stddev_in[i] << " " << mean_out[i] << " " << stddev_out[i] << endl;
  }
}

int main(int argc, char **argv) {
  if (argc < 3) {
    cerr << "Usage: " << argv[0] << " pcap-dir window-size" << endl;
    return 1;
  }

  char *dirname = argv[1];
  DIR *dir = opendir(dirname);
  if (dir == NULL) {
    cerr << "Couldn't open pcap dir " << dirname << "; exiting..." << endl;
    return 1;
  }

  window_size = atoi(argv[2]);
  if (window_size >= MAX_WINDOW_SIZE) {
    cerr << "Window size give was too large; must be less than " << MAX_WINDOW_SIZE << endl;
    return 1;
  }

  dirent *entry = NULL;
  while (entry = readdir(dir)) {
    if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) continue;

    char file[128];
    strcpy(file, dirname);
    file[strlen(dirname)] = '/';
    strcpy(file+strlen(dirname)+1, entry->d_name);

    pcap_t *handle = pcap_open_offline(file, errbuf);
    if (handle == NULL) {
      cerr << "Couldn't open pcap file " << file << "; skipping..." << endl;
      continue;
    }

    process_pcap_file(handle);
  }
  closedir(dir);

  compute_avg();
  return 0;
}
