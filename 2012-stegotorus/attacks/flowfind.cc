#include <pcap.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <dirent.h>

#include <iostream>
#include <fstream>
#include <vector>
#include <cmath>
#include <map>
#include <set>
using namespace std;

#define STDDEV_EPS 1
#define PROB_DELTA 13

#define TOR_ALPHA 0.1
#define TOR_SIZE 586
#define TOR_THRESH 0.4

#define DEFAULT_MATCH_THRESH 0

#define TRACK_SEQ_NUMS 100

#define ETHER_OFFSET 14

char errbuf[PCAP_ERRBUF_SIZE];
in_addr local;

bool is_local(in_addr& addr) {
  if (local.s_addr != 0) return addr.s_addr == local.s_addr;
  unsigned long first_byte = ntohl(addr.s_addr) / (1 << 24);
  return (first_byte == 10 || first_byte == 171);
}

struct packet {
  bool outgoing;
  u_short size;

  packet(bool outgoing, u_short size) : outgoing(outgoing), size(size) { }
};

struct flow {
  int len;
  vector<double> mean_in, mean_out;
  vector<double> stddev_in, stddev_out;
  vector<double> p_in, p_out;
};

struct in_addr_cmp {
  bool operator()(const in_addr& a, const in_addr& b) const {
    return a.s_addr < b.s_addr;
  }
};

struct conn_state {
  bool flag1, flag2;
  double torp;
  vector<packet> window;
  int widx;
  int pkt_count;
  set<int> seq[2];
};

flow to_find;
double match_thresh;

map<in_addr, conn_state *, in_addr_cmp> conns;
double max_match;

conn_state *new_conn_state() {
  conn_state *cs = new conn_state();
  cs->flag1 = cs->flag2 = false;
  cs->torp = 0;
  cs->window.resize(to_find.len, packet(0, false));
  cs->widx = 0;
  cs->pkt_count = 0;
  return cs;
}

void update_torp(conn_state *cs, int size, bool outgoing) {
  cs->torp = cs->torp*(1-TOR_ALPHA) + (size == TOR_SIZE)*TOR_ALPHA;
  if (cs->torp > TOR_THRESH && !cs->flag1) {
    // cout << "Tor identified" << endl;
    cs->flag1 = true;
  }
}

double get_log_prob(double mean, double stddev, double p, double value) {
  return PROB_DELTA - p - (mean-value)*(mean-value)/(2*stddev*stddev);
}

double compute_match(vector<packet>& window, int widx) {
  double cur_in = 0, cur_out = 0, match = 0;
  for (int i = 0; i < window.size(); i++) {
    int j = (widx + i) % window.size();
    if (window[j].outgoing) cur_out += window[j].size;
    else cur_in += window[j].size;

    match += get_log_prob(to_find.mean_in[i], to_find.stddev_in[i], to_find.p_in[i], cur_in);
    match += get_log_prob(to_find.mean_out[i], to_find.stddev_out[i], to_find.p_out[i], cur_out);
  }
  return match;
}

void update_state(conn_state *cs, int size, bool outgoing) {
  cs->window[cs->widx] = packet(outgoing, size);
  cs->widx++; cs->widx %= cs->window.size();
  cs->pkt_count++;

  update_torp(cs, size, outgoing);
  if (cs->flag1 && cs->pkt_count >= to_find.len) {
    double match = compute_match(cs->window, cs->widx);
    max_match = max(max_match, match);

    if (match > match_thresh) {
      // if (!cs->flag2)
      //   cout << "Match: " << cs->pkt_count << " " << match << endl;
      cs->flag2 = true;
    } else
      cs->flag2 = false;
  }
}

void packet_handler(u_char *args, const pcap_pkthdr *hdr, const u_char *pkt) {
  ip *ip_pkt = (ip *)(pkt + ETHER_OFFSET);
  tcphdr *tcp_pkt = (tcphdr *)((u_char *)ip_pkt + 4*ip_pkt->ip_hl);
  u_char *data = (u_char *)((u_char *)tcp_pkt + 4*tcp_pkt->th_off);

  in_addr remote = ip_pkt->ip_src;
  bool outgoing = false;
  if (is_local(remote)) {
    remote = ip_pkt->ip_dst;
    outgoing = true;
  }

  if (conns.find(remote) == conns.end())
    conns[remote] = new_conn_state();

  conn_state *cs = conns[remote];
  int seqno = ntohl(tcp_pkt->th_seq);
  if (cs->seq[outgoing].find(seqno) != cs->seq[outgoing].end()) {
    // cout << "Seqno " << seqno << " already seen; skipping..." << endl;
    return;
  }

  cs->seq[outgoing].insert(seqno);
  if (cs->seq[outgoing].size() > TRACK_SEQ_NUMS)
    cs->seq[outgoing].erase(cs->seq[outgoing].begin());

  int len = ntohs(ip_pkt->ip_len)-sizeof(ip)-sizeof(tcphdr);
  update_state(cs, len, outgoing);
}

void process_pcap_file(pcap_t *handle) {
  local.s_addr = 0;
  conns.clear();
  max_match = -1e6;

  pcap_pkthdr header;
  const u_char *pkt_ptr;
  while (pkt_ptr = pcap_next(handle, &header))
    packet_handler(NULL, &header, pkt_ptr);
}

int main(int argc, char **argv) {
  if (argc < 3) {
    cerr << "Usage: " << argv[0] << " flow-file pcap-dir" << endl;
    return 1;
  }

  ifstream flowfile(argv[1]);
  flowfile >> to_find.len;
  for (int i = 0; i < to_find.len; i++) {
    double m_in, s_in, m_out, s_out;
    flowfile >> m_in >> s_in >> m_out >> s_out;
    s_in += STDDEV_EPS; s_out += STDDEV_EPS;
    to_find.mean_in.push_back(m_in);
    to_find.stddev_in.push_back(s_in);
    to_find.p_in.push_back(0.5*log(2*M_PI*s_in*s_in));
    to_find.mean_out.push_back(m_out);
    to_find.stddev_out.push_back(s_out);
    to_find.p_out.push_back(0.5*log(2*M_PI*s_out*s_out));
  }
  flowfile.close();

  char *dirname = argv[2];
  DIR *dir = opendir(dirname);
  if (dir == NULL) {
    cerr << "Couldn't open pcap dir " << dirname << "; exiting..." << endl;
    return 1;
  }

  match_thresh = DEFAULT_MATCH_THRESH;
  if (argc >= 4) match_thresh = atoi(argv[3]);

  dirent *entry = NULL;
  int ct = 0;
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
    // cout << "\t" << ++ct << "\t" << max_match << endl;
    cout << "Max match in " << entry->d_name << ": " << max_match << endl;
  }
  closedir(dir);
  return 0;
}
