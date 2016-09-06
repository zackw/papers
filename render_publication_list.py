#! /usr/bin/python3

# Renders the contents of this repo as a directory of static HTML files.
# Controlled by papers.yml and lib/templates/.
# Requires PyYAML, bibtexparser, jinja2, and smartypants.

import os
import sys
sys.path.append(os.path.join(os.path.dirname(__file__), "lib"))

import argparse
import re
import shutil
import textwrap

import bibtexparser
import camel
import jinja2
import smartypants

M = jinja2.Markup

#
# Utility
#
def make_smart_html():
    A = smartypants.Attr
    # Maximum TeX compatibility
    SMARTY_MODE = A.q | A.b | A.B | A.D | A.e
    educate = smartypants.smartypants
    escape = jinja2.Markup.escape
    nentre = re.compile(r"&#([0-9]+);")
    def smart_html(s):
        """Convert ASCII to 'smart' quotes and then escape the string
           for use in HTML."""
        # The intermediate step is necessary because educate() emits
        # numeric HTML entities.  Blech.
        return escape(nentre.sub(lambda m: chr(int(m.group(1))),
                                 educate(str(s), SMARTY_MODE)))
    return smart_html

smart_html = make_smart_html()
del make_smart_html

def author_list_html(authors, homepages):
    """Make a formatted list of author names from AUTHORS.  If any names
       appear in HOMEPAGES, those names become hyperlinks to the respective
       URLs."""
    def iter_format_authors(authors, homepages):
        for au in authors:
            url = homepages.get(au)
            last, _, first = au.partition(", ")
            if first:
                au = first + " " + last
            else:
                au = last

            if url:
                yield M("<a href=\"{}\">{}</a>"
                        .format(url, smart_html(au)))
            else:
                yield smart_html(au)
    return M(", ").join(iter_format_authors(authors, homepages))


def author_list_bibtex(authors):
    return " and ".join(
        au if "," in au else ("{"+au+"}")
        for au in authors)

def wrap_bibtex_entry(entry):
    """Wrap long lines in a BibTeX entry neatly."""

    def iter_wrap_lines(entry):
        for ln in entry.splitlines():
            ln = ln.rstrip()
            if len(ln) <= 78 or ln[0] == "@":
                yield ln
                continue

            target = ln.find("{")
            if target == -1:
                yield ln
                continue

            yield from textwrap.wrap(ln, width=78,
                                     subsequent_indent=" "*(target+1))

    return "\n".join(iter_wrap_lines(entry))

#
# Each BibTeX entry type is a class here.
# (Right now we only need one.)
#
entry_types = camel.CamelRegistry()

class InProceedings:
    def __init__(self, *,
                 key, title, author, booktitle, year,
                 pdf=None,
                 pdf_url=None,
                 slides=None,
                 slides_url=None,
                 conf_url=None,
                 organization=None,
                 doi=None
    ):
        self.key          = key
        self.title        = title
        self.author       = author
        self.booktitle    = booktitle
        self.year         = year

        self.pdf          = pdf
        self.pdf_url      = pdf_url
        self.slides       = slides
        self.slides_url   = slides_url
        self.conf_url     = conf_url
        self.organization = organization
        self.doi          = doi

        if isinstance(self.author, str):
            if " and " in self.author:
                self.author = self.author.split(" and ")
            else:
                self.author = [self.author]

        if self.pdf and not self.pdf_url:
            self.pdf_url = os.path.basename(self.pdf)
        if self.slides and not self.slides_url:
            self.slides_url = os.path.basename(self.slides)

    def bibtex_entry(self):
        """Return a sanitized BibTeX entry for this paper.  Note that
           we do _not_ emit a url= field, because we don't know how to
           make it absolute.
        """
        entry = {
            "ENTRYTYPE": "inproceedings",
            "ID":        self.key,
            "title":     self.title,
            "author":    author_list_bibtex(self.author),
            "booktitle": self.booktitle,
            "year":      str(self.year)
        }
        if self.organization: entry["organization"] = self.organization
        if self.doi:          entry["doi"]          = self.doi

        db = bibtexparser.bibdatabase.BibDatabase()
        db.entries.append(entry)

        wr = bibtexparser.bwriter.BibTexWriter()
        wr.indent = "  "
        wr.align_values = True
        wr.display_order = [
            "title", "author", "booktitle", "year", "organization", "doi"
        ]
        return wrap_bibtex_entry(wr.write(db))

    def html_entry(self, homepages):
        """Return an HTML list entry for this paper.
           HOMEPAGES is a dict mapping author names (in last,first order)
           to websites."""

        title = smart_html(self.title)

        if self.pdf_url:
            title = M('“<a href="{}">{}</a>.”').format(self.pdf_url, title)
        else:
            title = "“" + title + ".”"

        if self.slides_url:
            title += M(' (<a href="{}">slides</a>)').format(
                self.slides_url)

        authors = author_list_html(self.author, homepages)

        booktitle = smart_html(self.booktitle)
        year      = smart_html(self.year)

        if self.organization:
            year = year + " " + smart_html(self.organization)

        conference = M("{} <i>{}</i>").format(year, booktitle)
        if self.conf_url:
            conference = M('<a href="{}">{}</a>').format(
                self.conf_url, conference)

        entry = M("<p>{}<br>{}.<br>{}.").format(title, authors, conference)
        if self.doi:
            entry += M(
                '<br><span class="doi">doi:'
                '<a href="https://dx.doi.org/{}">{}</a>'
                '</span>.').format(self.doi, self.doi)

        entry += M('</p>')
        return entry

@entry_types.loader("inproceedings", version=any)
def _load_InProceedings(data, version):
    return InProceedings(**data)

def main():
    with open(sys.argv[1]) as inf:
        data = camel.Camel([entry_types]).make_loader(inf).get_data()
    for section in reversed(data["pubs"]):
        sys.stdout.write(M("<h2>{}</h2>\n").format(
            smart_html(section["heading"])))
        for paper in reversed(section["items"]):
            sys.stdout.write(paper.html_entry(data["authors"]))
            sys.stdout.write("\n")

main()
