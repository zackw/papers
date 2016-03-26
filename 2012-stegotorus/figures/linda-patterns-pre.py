import sys

def processOne(fname, label):
    clusters = {}
    nextCluster = 1
    with open(fname, "r") as f:
        for line in f:
            line = line.strip()
            if line == "site,run,id,payload,dir": continue
            (sitE, ruN, iD, payloaD, diR) = line.split(',')
            clInd = ",".join((sitE,ruN,iD))

            clust = clusters.setdefault(clInd,
                                        { "i":nextCluster, "1":0, "2":0 })
            if clust["i"] == nextCluster:
                nextCluster += 1

            clust[diR] += 1
            if clust[diR] > 20: continue

            sys.stdout.write("{label},{i},{dir},{j},{payload}\n"
                             .format(label=label,
                                     i=clust["i"],
                                     dir=diR,
                                     j=clust[diR],
                                     payload=payloaD))

def processAll():
    sys.stdout.write("label,stream,dir,i,payload\n")
    processOne("tor.dir.csv", "Tor")
    processOne("http.dir.csv", "HTTP")
    processOne("stegotorus.dir.csv", "StegoTorus")

if __name__ == '__main__':
    processAll()
