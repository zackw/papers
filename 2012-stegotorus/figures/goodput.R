suppressPackageStartupMessages({
  library(grid)
  library(reshape2)
  library(ggplot2)
  library(tikzDevice)
})

data <- read.csv('goodput.tab', header=TRUE)

data$relay <- ordered(data$relay,
                      levels=c('tor', 'st.nosteg.1', 'st.http.2'),
                      labels=c('Tor', 'StegoTorus (chopper)',
                               'StegoTorus (HTTP)'))

options(tikzDocumentDeclaration=
        "\\documentclass[9pt]{extarticle}\\usepackage{txfonts}")
tikz(file="goodput.tex", width=3, height=1.5, standAlone=TRUE)
print(ggplot(data, aes(x=size, y=goodput, colour=relay, shape=relay)) +
  geom_line() + geom_point(size=1.5) +
  scale_x_continuous(limits=c(100,1000), breaks=seq(100,1000,by=100),
                     expand=c(0,0), name='File size (kB)') +
  scale_y_continuous(name="Goodput (kB/s)") +
  scale_colour_brewer(name="", type="qual", palette=2,
                      guide=guide_legend(title.position="right")) +
  scale_shape(name="", guide=guide_legend(title.position="right")) +
  theme_bw(base_size=8) +
  opts(panel.margin=unit(0.25,"cm"),
       panel.grid.major=theme_line(colour="grey90", size=0.2),
       panel.grid.minor=theme_line(colour="grey95", size=0.2),
       panel.background=theme_blank(),
       panel.border=theme_blank(),
       strip.background=theme_blank(),
       strip.text.y=theme_text(family="", size=8, angle=90),
       legend.key=theme_blank(),
       legend.title=theme_blank(),
       legend.key.height=unit(0.5,"lines"),
       legend.key.width=unit(0.8,"lines"),
       legend.text=theme_text(family="", size=6),
       legend.background=theme_rect(fill="white", colour=NA),
       legend.position=c(0.78, 0.47),
       axis.line=theme_segment(colour="black", size=0.2),
       plot.title=theme_blank(),
       plot.margin=unit(c(0.1,0.24,0,0),"cm")
       ))
invisible(dev.off())
