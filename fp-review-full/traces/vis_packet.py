#! /usr/bin/python3.3

import collections
import copy
import subprocess
import sys

class defaultlist(list):
    def __init__(self, *args, factory=lambda: None):
        list.__init__(self, *args)
        self.factory = factory

    def __fill__(self, idx):
        self.extend(self.factory()
                    for _ in range(idx - len(self) + 1))

    def __setitem__(self, idx, val):
        if idx == len(self):
            self.append(val)
        elif idx > len(self):
            self.__fill__(idx-1)
            self.append(val)
        else:
            list.__setitem__(self, idx, val)

    def __getitem__(self, idx):
        if idx >= len(self):
            self.__fill__(idx)
        return list.__getitem__(self, idx)

class Rect:
    __slots__ = tuple('xywh')
    def __init__(self, x=0, y=0, w=0, h=0):
        self.x = x
        self.y = y
        self.w = w
        self.h = h

    def cover(self, rect):
        """Enlarge self to cover rect."""
        self.x = min(self.x, rect.x)
        self.y = min(self.y, rect.y)
        self.w = max(self.w, rect.x + rect.w - self.x)
        self.h = max(self.h, rect.y + rect.h - self.y)

    def draw(self, f, x, y, color):
        f.write('<rect x="{}" y="{}" width="{}" height="{}" fill="{}"/>\n'
                .format(self.x + x, self.y + y, self.w, self.h, color))

class Packet:
    __slots__ = ("number", "stream", "time", "proto",
                 "direction", "host", "port", "flags",
                 "sslrecs", "pktlen", "paylen", "ssllens",
                 "rect")

    def __init__(self, line):
        f = line.strip().split(":")
        self.number    = int  (f[ 0])
        self.stream    = int  (f[ 1])
        self.time      = float(f[ 2]) * 1e3  # milliseconds
        self.proto     =       f[ 3]
        self.direction =       f[ 4]
        self.host      =       f[ 5]
        self.port      = int  (f[ 6])
        self.flags     =       f[ 7].split('.')
        self.sslrecs   =       f[ 8].split('.')
        self.pktlen    = int  (f[ 9])
        self.paylen    = int  (f[10])
        self.ssllens   =       f[11].split('.')
        self.rect      = None

    def layout(self, prevRect):
        r = Rect(x = max(self.time,
                         prevRect.x + prevRect.w + 2),
                 y = 0,
                 w = 2,
                 h = self.pktlen)
        if self.direction == 'up':
            r.y = -r.h
        self.rect = r
        return r

    def draw(self, f, x, y):
        if self.proto == 'udp':
            color = 'green'
        elif self.proto != 'tcp':
            color = 'red'
        elif self.paylen == 0:
            color = '#aaa'
        else:
            color = '#000'
        self.rect.draw(f, x, y, color)

class PacketStream:
    def __init__(self):
        self.packets = defaultlist()
        self.rect = None
        self.leader_y = 0

    def add_packet(self, pkt):
        assert self.rect is None
        assert self.packets[pkt.number] is None
        self.packets[pkt.number] = pkt

    def layout(self):
        npkts = []
        pRect = Rect()
        boundRect = None
        for p in self.packets:
            if p is not None:
                pRect = p.layout(pRect)
                if pRect.y < 0:
                    self.leader_y = max(self.leader_y, -pRect.y)
                if boundRect is None:
                    boundRect = copy.copy(pRect)
                else:
                    boundRect.cover(pRect)
                npkts.append(p)

        self.packets = npkts
        self.rect = boundRect
        return boundRect

    def draw(self, f, x, y, doLeader):
        f.write("<g>\n")
        if doLeader:
            f.write('<path fill="none" stroke="#000" d="M{},{}l{},0"/>'
                    .format(x + self.rect.x, y + self.rect.y + self.leader_y,
                            self.rect.w))
        for p in self.packets:
            p.draw(f, x, y)
        f.write("</g>")

class PacketVis:
    def __init__(self):
        self.streams = defaultlist(factory=PacketStream)

    def add_packet(self, line):
        pkt = Packet(line)
        self.streams[pkt.stream].add_packet(pkt)

    def draw(self, f):
        y = 0
        boundRect = Rect()
        streams = [s for s in self.streams
                   if len(s.packets) > 0]
        for s in streams:
            rect = s.layout()
            rect.y += y
            boundRect.cover(rect)
            y += rect.h
            y += 10

        f.write('<svg xmlns="http://www.w3.org/2000/svg" '
                'version="1.1" viewBox="0 0 {} {}">\n'
                .format(boundRect.w - boundRect.x,
                        boundRect.h - boundRect.y))
        x = -boundRect.x
        y = -boundRect.y
        doLeader = False
        for s in streams:
            if s is None: continue
            s.draw(f, x, y, doLeader)
            y += s.rect.h
            y += 10
            doLeader = True
        f.write("</svg>\n")

def main():
    argv = ["tshark", "-r", sys.argv[1],
            "-q", "-Xlua_script:vis_packet_extract.lua"]
    vis = PacketVis()
    with subprocess.Popen(argv,
                          stdout=subprocess.PIPE,
                          universal_newlines=True) as proc:
        try:
            for line in proc.stdout:
                vis.add_packet(line)
        except:
            proc.terminate()
            raise
    vis.draw(sys.stdout)

main()
