#! /usr/bin/Rscript

suppressPackageStartupMessages({
  library(grid)
  library(ggplot2)
  library(tikzDevice)
})

xlabs <- c('connection length (s)', 'bandwidth (decimal kilobytes)',
           'per-packet payload (bytes)')
xlevs <- c('connlens', 'bandwidths', 'payloads')
xhigh <- c(70, 1e5, 1500)

mlevs <- c('caida', 'm2', 'm3', 'm4')
mlabs <- c('CAIDA', 'vanilla Tor', 'obfsproxy', 'StegoTorus')

read.one <- function(xl, hi, ml) {
  d <- scan(paste(xl, "-", ml, ".XY.csv", sep=""),
            what=list(x=double(),y=double()), sep=',',
            multi.line=FALSE, quiet=TRUE)
  f <- is.finite(d$x) & d$x < hi & !duplicated(d$x)
  g <- d$x == min(d$x[d$x >= hi])

  x <- c(0, d$x[f], hi)
  y <- c(0, d$y[f], d$y[g][1])

  return(data.frame(plot  = ordered(xl, levels=xlevs, labels=xlabs),
                    trace = ordered(ml, levels=mlevs, labels=mlabs),
                    x     = x,
                    y     = y))
}

data = data.frame()

for (x in 1:3)
  for (m in mlevs)
    data <- rbind(data, read.one(xlevs[x], xhigh[x], m))

data$x[data$plot == 'bandwidth (decimal kilobytes)'] <-
  data$x[data$plot == 'bandwidth (decimal kilobytes)'] / 1000

p <- ggplot(data, aes(x=x, y=y, group=trace, linetype=trace)) +
       facet_wrap(~plot, scales='free_x') +
       geom_step(direction='vh') +
       scale_x_continuous(expand=c(0,0)) +
       scale_y_continuous(expand=c(0,0)) +
       scale_linetype_manual(values=c("CAIDA"       = "solid",
                                      "vanilla Tor" = "dashed",
                                      "obfsproxy"   = "dotdash",
                                      "StegoTorus"  = "dotted")) +
       labs(x=NULL, y="Pr(x <= X)", linetype=NULL) +
       theme_bw(base_size=9) +
       opts(panel.margin=unit(0.5,"cm"),
            panel.grid.major=theme_line(colour="grey90", size=0.2),
            panel.grid.minor=theme_line(colour="grey95", size=0.2),
            panel.border=theme_blank(),
            strip.background=theme_blank(),
            legend.key=theme_blank(),
            axis.line=theme_segment(colour="black", size=0.2),
            plot.title=theme_blank())

tikz(file="ecdf-cl-bw-pl.raw.tex", width=6.5, height=2, standAlone=TRUE)
print(p)
invisible(dev.off())
