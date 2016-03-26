#! /usr/bin/Rscript

suppressPackageStartupMessages({
  library(plyr)
  library(ggplot2)
  library(tikzDevice)
})

colsplit.perl <- function(x, split="", names)
{
  x <- as.character(x)
  vars <- as.data.frame(do.call(rbind, strsplit(x, split, perl=TRUE)))
  names(vars) <- names
  as.data.frame(lapply(vars, function(x) type.convert(as.character(x))))
}

plen <- read.csv("ec.9001-993-443.tab.xz")
plen <- subset(plen, port == 443 & saw.syn == TRUE)

plen$port <- NULL
plen$saw.syn <- NULL
plen$tag <- NULL
plen$n <- factor(1:nrow(plen))

plen.dnames <- setdiff(colnames(plen), c("origin", "n"))

# Estimator of "Tor-ness" of a packet stream based only on the sizes of
# the first 20 data-carrying packets, unidirectionally.
tau <- cbind(origin=plen$origin,
             n=plen$n,
             data.frame(t(apply(plen[,plen.dnames], 1, function(row) {
  rv <- (cumsum(ifelse(row == 586|row==1098|row==1172, 1,
                       ifelse(row < 1250,
                              # Penalize long packets more at the beginning,
                              # short packets more at the end.
                              seq(-0.1, -1, length.out=length(row)),
                              seq(-1, -0.1, length.out=length(row)))))
         / 1:length(row)) / 2 + 0.5
  names(rv) <- paste("t", 0:(length(row)-1), sep="")
  rv
}))))

tau.dnames <- setdiff(colnames(tau), c("origin", "n"))

# K-means cluster analysis doesn't do what we want for this data set, i.e.
# separate the tiny handful of Tor streams (67) from 63,500 others.
# The value of tau for the 19th packet, however, does exactly that,
# just like we designed it to do.

category <- factor(ifelse(tau$t19 < 0.4, "Not Tor", "Tor"))

counts <- rle(sort(unclass(category)))$lengths
levels(category) <- paste(levels(category), " (", comma(counts), " flows)",
                          sep="")

# Combine the categorization with the tau and plen values.
all <- cbind(data.frame(cat=category), plen, tau[,tau.dnames])

# Reshape for plotting.
all.m <- melt(all, id.vars=c("cat","origin","n"))
all.m <- cbind(all.m,
               colsplit.perl(all.m$variable, split="(?<=[lt])",
                             names=c("var","i")))

all.c <- cast(all.m, origin + cat + n + i ~ var)

# Data adjustments.  `i` is currently 0-19 when we want 1-20; `l` and
# `t` need manual binning, because stat_bin2d doesn't work with
# geom_point.

all.c$i <- all.c$i + 1
all.c$ll <- all.c$l
tobin <- with(all.c, l != 586 & l != 1098 & l != 1172)
all.c$ll[tobin] <- round(all.c$ll[tobin]/10)*10

all.c$tt <- round(all.c$t, 2)

# These graphics require manual adjustment; see the comments at the
# top of the current https-patterns.tex.

tikz(file="https-patterns-raw.tex", width=6.5, height=3,
     standAlone=TRUE)
print(ggplot(all.c, aes(x=i, group=i, y=ll)) +
  stat_sum() +
  facet_wrap(~cat, nrow=1) +
  scale_x_continuous(limits=c(1,20), breaks=c(1,5,10,15,20),
                     minor_breaks=1:20, expand=c(0,0)) +
  scale_y_continuous(limits=c(0,1500), breaks=c(0,100,586,1098,1172,1250,1500),
                     minor_breaks=seq(0,1500,by=100), expand=c(0,0)) +
  scale_size(to=c(0.25,4),
             name="\\% obs",
             breaks=c(.2,.4,.6,.8),
             labels=c("20\\%", "40\\%", "60\\%", "80\\%")) +
  labs(x=NULL, y="Packet size") +
  theme_bw(base_size=9) +
  opts(panel.margin=unit(0.5,"cm"),
       panel.grid.major=theme_line(colour="grey90", size=0.4),
       panel.grid.minor=theme_line(colour="grey95", size=0.4),
       panel.border=theme_blank(),
       strip.background=theme_rect(fill="grey80", colour="grey80"),
       legend.key=theme_blank()))
invisible(dev.off())

# wound up removing this figure again because the current text describes
# the fingerprint technique differently
#
## tikz(file="https-patterns-raw-bot.tex", width=6.5, height=2,
##      standAlone=TRUE)
## print(ggplot(all.c, aes(x=i, group=i, y=tt)) +
##   stat_sum() +
##   facet_wrap(~cat, nrow=1) +
##   scale_x_continuous(limits=c(1,20), breaks=c(1,5,10,15,20),
##                      minor_breaks=1:20, expand=c(0,0)) +
##   scale_y_continuous(limits=c(0,1), expand=c(0,0)) +
##   scale_size(to=c(0.25,4),
##              name="\\% obs",
##              breaks=c(.2,.4,.6,.8),
##              labels=c("20\\%", "40\\%", "60\\%", "80\\%")) +
##   labs(x=NULL, y="Tor-ness estimate $\\tau$") +
##   theme_bw(base_size=9) +
##   opts(panel.margin=unit(0.5,"cm"),
##        panel.grid.major=theme_line(colour="grey90", size=0.4),
##        panel.grid.minor=theme_line(colour="grey95", size=0.4),
##        panel.border=theme_blank(),
##        strip.background=theme_blank(),
##        strip.text.x=theme_blank(),
##        legend.key=theme_blank()))
## invisible(dev.off())
