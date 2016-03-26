#! /usr/bin/Rscript
suppressPackageStartupMessages({
  library(ggplot2)
  library(tikzDevice)
})

s.log.10 <- function(x)
  suppressWarnings(ifelse(abs(x)<=2.25, 0,
                          ifelse(x<0, -log10(-x) + 2.25, log10(x) - 2.25)))
s.exp.10 <- function(x)
  suppressWarnings(ifelse(x == 0, 0,
                          ifelse(x<0, -10^(-(x - 2.25)), 10^(x + 2.25))))

TransSymmLog10 <- Trans$new("symmlog10", s.log.10, s.exp.10, s.exp.10)

fb <- read.csv("fb-detect.csv")
fb$X <- reorder(fb$N, -fb$SLP)
fb$LABEL <- paste("    ", fb$LABEL, sep="")
fb$LABEL[fb$SLP > 0 | fb$SLP < -2000] <- ""

tikz(file="fb-detect.tex", width=3, height=3, standAlone=TRUE)
ggplot(fb, aes(x=X, y=SLP, shape=CLS)) +
  geom_point(size=1) + geom_text(aes(label=LABEL), hjust=0, size=2) +
  scale_shape_manual("", values=c("Facebook"=15, "Other"=1)) +
  scale_y_continuous("Shifted log-probability", trans=TransSymmLog10,
                     limits=c(-300000,3000),
                     breaks=c(-300000,-10000,-500,0,500,2000),
                     formatter="comma") +
  scale_x_discrete("", expand=c(0,1)) +
  theme_bw(base_size=8) +
  opts(panel.border=theme_blank(),
       legend.key=theme_blank(),
       legend.title=theme_blank(),
       legend.background=theme_rect(fill="white",colour=NA),
       legend.position=c(0.85,0.9),
       axis.text.x=theme_blank(),
       axis.title.x=theme_blank()
       )
invisible(dev.off())
