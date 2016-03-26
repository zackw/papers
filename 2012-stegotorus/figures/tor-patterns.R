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

plen <- read.csv("ec.9001.tab.xz")
plen <- subset(plen, saw.syn == TRUE)

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

clust <- (function(block) {
  O <- factor(block$origin)
  N <- block$n
  M <- block[,setdiff(colnames(block), c("origin", "n"))]

  # K-means clustering is nondeterministic.  4-byte seed generated
  # from /dev/urandom.  I don't _think_ we need to pin down the normal
  # distribution generator but it can't hurt.
  set.seed(97500674, kind="Mersenne-Twister", normal.kind="Inversion")

  # Visual inspection suggests two "tor" and one "not-tor" clusters in
  # the data set.
  CC <- kmeans(M, centers=3)

  C <- factor(CC$cluster)

  # For each data vector, compute its Euclidean distance from the center
  # of its cluster.  (It doesn't much matter which distance metric we
  # use, since it's only going to be used to rank them.  Euclidean is
  # easy to reason about.)
  D <- rep(0, nrow(M))
  for (i in 1:nrow(M)) {
    D[i] <- dist(rbind(M[i,], CC$centers[CC$cluster[i],]))
  }

  # Assemble the data frame to be returned, and sort it from smallest
  # to largest distance within each cluster.
  return(ddply(data.frame(origin=O, cluster=C, distance=D, n=N),
               .(cluster),
               function(b) b[order(b$distance),]))
})(tau)

# Combine the cluster results with the tau and plen values.
all <- cbind(clust, plen[clust$n, plen.dnames], tau[clust$n, tau.dnames])

# Reshape for plotting.

all.m <- melt(all, id.vars=c("origin","cluster","n","distance"))
all.m <- cbind(all.m,
               colsplit.perl(all.m$variable, split="(?<=[lt])",
                             names=c("var","i")))

all.c <- cast(all.m, origin + cluster + distance + n + i ~ var)

# Clusters 1 and 3 are (apparent) Tor traffic; cluster 2 is non-Tor.

# This graphic requires some manual adjustment; see the comments at the
# top of the current tor-patterns.tex.

tikz(file="tor-patterns-raw.tex", width=6.5, height=3)
print(ggplot(subset(all.c, cluster!=2), aes(x=i, y=l, size=..n..)) +
  stat_sum() + facet_wrap(~cluster) +
  scale_x_continuous(limits=c(1,20), breaks=c(1,5,10,15,20),
                     minor_breaks=1:20, expand=c(0,0)) +
  scale_y_continuous(limits=c(0,1500), breaks=c(0,100,586,1098,1172,1250,1500),
                     minor_breaks=seq(0,1500,by=100), expand=c(0,0)) +
  scale_size(to=c(0.5,4)) +
  labs(x=NULL, y="Packet size", size="Count") +
  theme_bw() + opts(strip.text.x=theme_blank(),
                    strip.background=theme_blank(),
                    panel.margin=unit(0.5,"cm"),
                    panel.grid.major=theme_line(colour="grey90"),
                    panel.grid.minor=theme_line(colour="grey95"),
                    panel.border=theme_blank(),
                    legend.key=theme_blank()))
invisible(dev.off())

# Alternative, using boxplots
#tikz(file="classify-9001-bp-raw.tex", width=6.5, height=3)
#print(ggplot(subset(all.c, cluster!=2), aes(x=i, group=i, y=l)) +
#  geom_boxplot(size=1/3, outlier.size=.8) + facet_wrap(~cluster) +
#  scale_x_continuous(breaks=c(1,5,10,15,20),
#                     minor_breaks=1:20, expand=c(0,0)) +
#  scale_y_continuous(limits=c(0,1500), breaks=c(0,100,586,1098,1172,1250,1500),
#                     minor_breaks=seq(0,1500,by=100), expand=c(0,0)) +
#  labs(x=NULL, y="Packet size") +
#  theme_bw() + opts(strip.text.x=theme_blank(),
#                    strip.background=theme_blank(),
#                    panel.margin=unit(0.5,"cm"),
#                    panel.grid.major=theme_line(colour="grey90"),
#                    panel.grid.minor=theme_line(colour="grey95"),
#                    panel.border=theme_blank(),
#                    legend.position="none"))
#invisible(dev.off())

# I've gotten a lot of mileage out of this diagnostic plot of the
# classification when tweaking the above code, but it is too big and
# cryptic to put into the paper.
#
# theme_donly <- function(base_size=12)
#   structure(list(
#     axis.line = theme_blank(),
#     axis.text.x = theme_blank(),
#     axis.text.y = theme_blank(),
#     axis.ticks = theme_blank(),
#     axis.title.x = theme_blank(),
#     axis.title.y = theme_blank(),
#     axis.ticks.length = unit(0, "lines"),
#     axis.ticks.margin = unit(0, "lines"),
#     legend.position = "none",
#     panel.background = theme_blank(),
#     panel.border = theme_blank(),
#     panel.grid.major = theme_blank(),
#     panel.grid.minor = theme_blank(),
#     panel.margin = unit(0, "lines"),
#     plot.background = theme_blank(),
#     strip.text.x=theme_blank(),
#     strip.text.y=theme_blank(),
#     strip.background=theme_blank()
#     #,plot.margin = unit(0*c(-1.5, -1.5, -1.5, -1.5), "lines")
#   ), class = "options")
# ggplot(all.c) + facet_wrap(cluster ~ n) + ylim(0,1) + theme_donly() +
#   geom_segment(aes(x=i, xend=i, yend=l/1500), y=0, colour="#aaaaaa") +
#   geom_line(aes(x=i, y=t, colour=cluster)) +
#   geom_hline(y=0.4, size=0.25)
