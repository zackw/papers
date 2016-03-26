% LaTeX article-subclass for CMU qual review-papers.
% Original version, 2012/09/19  Zack Weinberg.
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{cmuecequal}[2012/09/19 Article specialization for CMU ECE
                                      qualifying papers]

% 10 point, letter paper, two column, pass other options down to article.
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
\ProcessOptions\relax
\LoadClass[12pt,letterpaper,twocolumn]{article}

% 0.5” margins left and right.  9” of vertical page area, with
% geometry's defaults for margin ratio. 0.35” between columns.
\RequirePackage{geometry}
\geometry{hmargin=0.5in,textheight=9in,columnsep=0.35in}

% These packages must be loaded before any fonts.
\RequirePackage[utf8]{inputenc}
\RequirePackage[T1]{fontenc}
\RequirePackage{textcomp}

% inputenc doesn't set the space factor of Unicode close curly quote
% correctly.
\AtBeginDocument
 {\sfcode\csname\encodingdefault\string\textquotedblright\endcsname=0}

% Font choices up for debate, but I think these are inarguably
% superior to Computer Modern, and should be available with any
% recent version of TeX Live.
\RequirePackage[charter]{mathdesign}
\RequirePackage{inconsolata}

% This package must be loaded after any fonts.
\RequirePackage[final]{microtype}

% These packages must be loaded in this order.
\RequirePackage[hyphens]{url}
\RequirePackage{color}
\RequirePackage[colorlinks=true,urlcolor=blue,citecolor=dgreen]{hyperref}
\hypersetup{pageanchor=false}
\definecolor{dgreen}{RGB}{0,127,0}

% Title adjustments.
\RequirePackage{titling}
\setlength{\droptitle}{-2em}
\pretitle{\begingroup\centering\normalfont\Large\bfseries}
\posttitle{\\\endgroup\vspace*{4pt}}
\preauthor{\begingroup\centering\normalfont\large}
\postauthor{\\\endgroup\vspace*{6pt}}
\let\maketitlehookc=\@gobble % this suppresses the date
\def\maketitlehookd{\begingroup\centering\normalfont\bfseries
ECE Department\\
Carnegie Mellon University\\
U.S.A.\\\endgroup}

% Abstract adjustments.
\renewcommand{\abstractname}{\centering Abstract}

% TBD: do we want something cleverer?
\bibliographystyle{acmurl}
\newcommand*{\BIBdecl}{%
  \footnotesize
  % cribbed from biblatex 1.7; / moved from Breaks to BigBreaks to
  % ensure that 'http://' is not broken after the colon
  \Urlmuskip=0mu plus 3mu\relax
  \mathchardef\UrlBigBreakPenalty=100\relax
  \mathchardef\UrlBreakPenalty=200\relax
  \def\UrlBigBreaks{\do\:\do\-\do\/}%
  \def\UrlBreaks{%
    \do\.\do\@\do\\\do\!\do\_\do\|\do\;\do\>\do\]\do\)\do\}%
    \do\,\do\?\do\'\do\+\do\=\do\#\do\$\do\&\do\*\do\^\do\"}%
}


\endinput
