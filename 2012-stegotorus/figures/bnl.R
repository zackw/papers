suppressPackageStartupMessages({
  library(grid)
  library(plyr)
  library(ggplot2)
  library(tikzDevice)
})

bnl <- read.csv('bnl.tab', header=TRUE)

bnl$rate <- factor(bnl$rate,
                   labels=paste(sort(unique(bnl$rate)), 'kB/s stream'))

bnl$relay <- ordered(bnl$relay,
                     levels=c('direct', 'tor', 'st.nosteg.1',
                              'st.http.2', 'st.http.4', 'st.http.6'),
                    labels=c('Direct connection',
                             'Tor',
                             'StegoTorus (chopper only)',
                             'StegoTorus (HTTP, 2 parallel connections)',
                             'StegoTorus (HTTP, 4 parallel connections)',
                             'StegoTorus (HTTP, 6 parallel connections)'))

med_hinges <- function(x)
  rename(data.frame(t(fivenum(x)[2:4])), c(X1="ymin", X2="y", X3="ymax"))

options(tikzDocumentDeclaration=
        "\\documentclass[9pt]{extarticle}\\usepackage{txfonts}")

tikz(file="bnl.tex", width=6.5, height=2, standAlone=TRUE)
print(ggplot(subset(bnl, relay!='Direct connection'),
             aes(x=lat, y=down, colour=relay, shape=relay)) +
  stat_summary(geom='pointrange', fun.data='med_hinges', size=0.3) +
  stat_summary(geom='line', fun.y='median', size=0.3) +
  facet_wrap(~rate, nrow=1) +
  scale_x_continuous(expand=c(0,0), limits=c(100,450),
                     name='Round-trip latency (ms)') +
  scale_y_continuous(expand=c(0,0), limits=c(0,600),
                     name='Sustained download rate\n(kB/s on wire)') +
  scale_colour_manual(values=c(
     'Tor'='#377EB8',
     'StegoTorus (chopper only)'='#4DAF4A',
     'StegoTorus (HTTP, 2 parallel connections)'='#FF7F00',
     'StegoTorus (HTTP, 4 parallel connections)'='#E41A1C',
     'StegoTorus (HTTP, 6 parallel connections)'='#984EA3'),
     guide=guide_legend(title.position="right")) +
  scale_shape_manual(values=c(
     'Tor'=6,
     'StegoTorus (chopper only)'=2,
     'StegoTorus (HTTP, 2 parallel connections)'=0,
     'StegoTorus (HTTP, 4 parallel connections)'=1,
     'StegoTorus (HTTP, 6 parallel connections)'=5),
     guide=guide_legend(title.position="right")) +
  theme_bw(base_size=8) +
  opts(panel.margin=unit(0.4,"cm"),
       panel.grid.major=theme_line(colour="grey90", size=0.2),
       panel.grid.minor=theme_line(colour="grey95", size=0.2),
       panel.background=theme_blank(),
       panel.border=theme_blank(),
       strip.background=theme_blank(),
       strip.text.x=theme_text(family="", size=8, face="bold"),
       legend.key=theme_blank(),
       legend.title=theme_blank(),
       legend.key.height=unit(0.6,"lines"),
       legend.key.width=unit(0.8,"lines"),
       legend.text=theme_text(family="", size=6),
       legend.background=theme_rect(fill="white", colour=NA),
       legend.position=c(0.18, 0.83),
       axis.line=theme_segment(colour="black", size=0.2),
       plot.title=theme_blank(),
       plot.margin=unit(c(0,0.24,0,0),"cm")
       ))
invisible(dev.off())
