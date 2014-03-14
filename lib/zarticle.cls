% LaTeX article-subclass with a bunch of personal customizations.
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{zarticle}[2013/01/24 Personal article class customizations]

% Special option for minimal margins for screen drafts.
\newif\if@tinymargin \@tinymarginfalse
\DeclareOption{tinymargin}{\@tinymargintrue}

% 10 point, letter paper, pass other options down to article.
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
\ProcessOptions\relax
\LoadClass[12pt,letterpaper,onecolumn]{article}

\RequirePackage{geometry}
\if@tinymargin
  \geometry{textwidth=6in, textheight=10in, columnsep=0.35in,
            lmargin=0.1in, rmargin=0.1in, tmargin=0.1in, bmargin=0.1in,
            paperwidth=6.8in, paperheight=10.2in}
  \AtBeginDocument{\pagestyle{empty}}
\else
  % 0.5" left margin, 2" right.  10" of vertical page area, with
  % geometry's defaults for margin ratio.
  \geometry{lmargin=0.5in,rmargin=2in,textheight=10in}
\fi

% These packages must be loaded before any fonts.
\RequirePackage[utf8]{inputenc}
\RequirePackage[T1]{fontenc}
\RequirePackage{textcomp}

% inputenc doesn't set the space factor of Unicode close curly quote
% correctly.
\AtBeginDocument
 {\sfcode\csname\encodingdefault\string\textquotedblright\endcsname=0}

% float alignment - look into `floatrow' if this needs to get more
% complicated
\g@addto@macro\@floatboxreset\centering

% font choices
\RequirePackage{lmodern}  % backstop - ensure no T1-incompatible fonts
\RequirePackage{fourier}   % body Utopia and matching math
\RequirePackage[defaultsans,scale=0.95]{lato}
%\renewcommand{\sfdefault}{iwona} % looks better with Utopia

% This package must be loaded after any fonts.
\RequirePackage[final]{microtype}

% These packages must be loaded in this order.
\RequirePackage[hyphens]{url}
\RequirePackage{xcolor}
\RequirePackage[colorlinks=true,urlcolor=blue,citecolor=dgreen]{hyperref}
\definecolor{dgreen}{RGB}{0,127,0}
\urlstyle{sf}

% Personal biblatex setup (not corresponding to anyone's house style)
\RequirePackage[american]{babel}
\RequirePackage{csquotes}
\RequirePackage[bibstyle=numeric-web,citestyle=numeric,backend=biber,
                sortcites=true,firstinits=true,maxbibnames=99]{biblatex}
\renewcommand{\bibfont}{\footnotesize}

\endinput
