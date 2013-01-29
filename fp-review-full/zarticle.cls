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
\RequirePackage[bibstyle=numeric-web,citestyle=numeric,
                backend=biber,sortcites=true]{biblatex}

\endinput
