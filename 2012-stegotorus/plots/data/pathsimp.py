#! /usr/bin/python

import re

def main(inf, outf):
    el = re.compile(r"""\A\t\(([ 0-9.]+),([ 0-9.]+)\) (--|;)\n\Z""")

    x0 = ""
    y0 = ""
    x1 = ""
    y1 = ""

    for line in inf:
        m = el.match(line)
        if m is None:
            outf.write(line)
            continue

        x  = m.group(1)
        y  = m.group(2)
        op = m.group(3)

        # We are looking for sequences of path knots that differ only in
        # one coordinate, e.g.
        #
        #    (10,0) --
        #    (10,1) --
        #    (10,2) --
        #    (10,3) ;
        #
        # can be simplified to
        #
        #    (10,0) --
        #    (10,3) ;
        #
        # As a special case, if we hit op == ';' we know we have come to the
        # end of this path, so we must emit the current point and reset.

        if op == ';':
            if x0 != "":
                outf.write("\t({},{}) --\n".format(x0, y0))
            if x1 != x0 or y1 != y0:
                outf.write("\t({},{}) --\n".format(x1, y1))
            outf.write(line)
            x0 = ""
            y0 = ""
            x1 = ""
            y1 = ""
            continue

        if x != x0 and y != y0:
            if x0 != "":
                outf.write("\t({},{}) --\n".format(x0, y0))
            if x1 != x0 or y1 != y0:
                outf.write("\t({},{}) --\n".format(x1, y1))
            x0 = x
            x1 = x
            y0 = y
            y1 = y
        elif x0 == "":
            x0 = x
            x1 = x
            y0 = y
            y1 = y
        else:
            x1 = x
            y1 = y

if __name__ == '__main__':
    import sys
    main(sys.stdin, sys.stdout)
