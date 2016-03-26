#! /usr/bin/Rscript

suppressPackageStartupMessages({
  library(plyr)
  library(reshape2)
  library(ggplot2)
  library(grid) # for 'unit'
  library(tikzDevice)
})

p <- pipe("python linda-patterns-pre.py", open="r")
all <- read.csv(p)
close(p)
rm(p)

# downsample streams so that all three classifications have the same length
n <- min(daply(all, .(label), function(block) length(unique(block$stream))))
all <- ddply(all, .(label), function(block, n) {
  k <- length(unique(block$stream))
  if (k <= n)
    block
  else
    block[block$stream %in% sample(k, n),]
}, n*4)

# bin the payload lengths
tobin <- with(all, payload != 586)
all$payload[tobin] <- round(all$payload[tobin]/10)*10

# proper labels for 'dir'
all$dir <- ordered(all$dir, labels=c("client $\\rightarrow$ server",
                                     "server $\\rightarrow$ client"))

tikz(file="linda-patterns.tex", width=6.5, height=3, standAlone=TRUE)
print(
  ggplot(all, aes(x=i, group=i, y=payload)) +
  stat_sum(aes(size=..n..)) +
  facet_grid(dir ~ label) +
  scale_x_continuous(limits=c(1,20), breaks=c(1,5,10,15,20),
                     minor_breaks=1:20, expand=c(0,0)) +
  scale_y_continuous(limits=c(0,1500), breaks=c(0,200,586,1000,1500),
                     minor_breaks=seq(0,1500,by=100), expand=c(0,0)) +
  scale_size(range=c(0.5,3)) +
  labs(x="Packet number (zero-length ACKs discarded)",
       y="TCP payload size",
       size="\\# packets\nthis size") +
  theme_bw(base_size=9) +
  opts(panel.margin=unit(0.5,"cm"),
       panel.grid.major=theme_line(colour="grey90", size=0.4),
       panel.grid.minor=theme_line(colour="grey95", size=0.4),
       panel.border=theme_blank(),
       strip.background=theme_rect(fill="grey80", colour="grey80"),
       legend.key=theme_blank())
)
invisible(dev.off())
