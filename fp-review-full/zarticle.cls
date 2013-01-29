% LaTeX article-subclass with a bunch of personal customizations.
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{zarticle}[2013/01/24 Personal article class customizations]

% 10 point, letter paper, two column, pass other options down to article.
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
\ProcessOptions\relax
\LoadClass[10pt,letterpaper,twocolumn]{article}

% 0.5″ margins left and right.  9″ of vertical page area, with
% geometry's defaults for margin ratio. 0.35″ between columns.
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
\definecolor{dgreen}{RGB}{0,127,0}

% ACM-like biblatex setup.
\RequirePackage[backend=biber,style=numeric,firstinits=true,maxnames=99,
                sortcites=true]{biblatex}
\DeclareNameAlias{default}{last-first}
\DeclareFieldFormat
  [article,inbook,incollection,inproceedings,patent,thesis,unpublished]
  {title}{#1}
\DeclareFieldFormat{pages}{#1}
\DeclareFieldFormat{url}{\url{#1}}
\renewcommand{\intitlepunct}{\space}
\renewbibmacro{in:}{}
\renewbibmacro*{volume+number+eid}{}
\renewbibmacro*{chapter+pages}{}
\renewbibmacro*{note+pages}{}
\renewbibmacro*{publisher+location+date}{%
  \printlist{publisher}%
  \setunit*{\addcomma\space}%
  \printlist{location}%
  \setunit*{\addcomma\space}%
  \usebibmacro{date}%
  \newunit}
\AtBeginBibliography{%
  \footnotesize
  \renewcommand*{\mkbibnamelast}[1]{\textsc{#1}}%
  % relative to stock biblatex, / moved from Breaks to BigBreaks to
  % discourage 'http://' being broken after the colon
  \renewcommand*{\biburlsetup}{%
  \Urlmuskip=0mu plus 3mu\relax
  \mathchardef\UrlBigBreakPenalty=100\relax
  \mathchardef\UrlBreakPenalty=200\relax
  \def\UrlBigBreaks{\do\:\do\-\do\/}%
  \def\UrlBreaks{%
    \do\.\do\@\do\\\do\!\do\_\do\|\do\;\do\>\do\]\do\)\do\}%
    \do\,\do\?\do\'\do\+\do\=\do\#\do\$\do\&\do\*\do\^\do\"}%
  \ifnumgreater{\value{biburlnumpenalty}}{0}
    {\def\do##1{\appto\UrlSpecials{\do##1{\mathchar`##1 \penalty\value{biburlnumpenalty}}}}%
     \do\1\do\2\do\3\do\4\do\5\do\6\do\7\do\8\do\9\do\0}
    {}%
  \ifnumgreater{\value{biburlucpenalty}}{0}
    {\def\do##1{\appto\UrlSpecials{\do##1{\mathchar`##1 \penalty\value{biburlucpenalty}}}}%
     \do\A\do\B\do\C\do\D\do\E\do\F\do\G\do\H\do\I\do\J
     \do\K\do\L\do\M\do\N\do\O\do\P\do\Q\do\R\do\S\do\T
     \do\U\do\V\do\W\do\X\do\Y\do\Z}
    {}%
  \ifnumgreater{\value{biburllcpenalty}}{0}
    {\def\do##1{\appto\UrlSpecials{\do##1{\mathchar`##1 \penalty\value{biburllcpenalty}}}}%
     \do\a\do\b\do\c\do\d\do\e\do\f\do\g\do\h\do\i\do\j
     \do\k\do\l\do\m\do\n\do\o\do\p\do\q\do\r\do\s\do\t
     \do\u\do\v\do\w\do\x\do\y\do\z}
    {}%
  \let\do=\noexpand}
}
\endinput
