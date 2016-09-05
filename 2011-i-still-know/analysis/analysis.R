library(ggplot2)

doplot <- function(file, width, height, plot) {
  ftmp <- paste(file, "-.pdf", sep="")
  ffin <- paste("../", file, ".pdf", sep="")

  pdf(file=ftmp, width=width, height=height)
  print(plot)
  dev.off()
  embedFonts(ftmp, format="pdfwrite", outfile=ffin,
     options="-dSubsetFonts=true -dEmbedAllFonts=true -dPDFSETTINGS=/prepress")
  system(paste("rm", ftmp))
}

d.charcaptcha <- read.csv("charcaptcha.csv")
d.chessboard <- read.csv("chess.csv")
d.matching <- read.csv("matching.csv")
d.wordcaptcha <- read.csv("wordcaptcha.csv")
d.noninteractive <- read.csv("noninteractive.csv")

# accuracy
d.error <- na.omit(melt(structure(list(charcaptcha=d.charcaptcha$error,
                                       chessboard=d.chessboard$error,
                                       matching=d.matching$error,
                                       wordcaptcha=d.wordcaptcha$error),
                                  varname="task")))

# Note: the levels/labels lists have to be backward from the
# top-to-bottom order we want in the final graph, because of how
# coord_flip() works.
d.error$task <- ordered(d.error$task,
    levels=c("matching", "chessboard", "charcaptcha", "wordcaptcha"),
    labels=c("Pattern match", "Chessboard", "Char. CAPTCHA", "Word CAPTCHA"))

p.error <- function(data)
  ggplot(data, aes(x=task, y=1-value)) +
  geom_boxplot() +
  scale_y_continuous(formatter="percent") +
  coord_flip() +
  opts(axis.title.x=theme_blank(), axis.title.y=theme_blank())

doplot("accuracy", 5, 3, p.error(d.error))


# queries per minute
d.qpm <- na.omit(melt(structure(list(
            charcaptcha=d.charcaptcha$qpm,
            chessboard=d.chessboard$qpm,
            matching=d.matching$qpm,
            wordcaptcha=d.wordcaptcha$qpm,
            direct=d.noninteractive$qpm.direct,
            indirect=d.noninteractive$qpm.indirect,
            timing=d.noninteractive$qpm.timing),
                                varname="task")))

d.qpm$type <- factor(with(d.qpm,
                          task=="direct"|task=="indirect"|task=="timing"),
                     labels=c("interactive", "automated"))

d.qpm$task <- ordered(d.qpm$task,
    levels=c("timing", "indirect", "direct",
             "matching", "chessboard", "charcaptcha", "wordcaptcha"),
    labels=c("Auto (timing)", "Auto (indirect)", "Auto (direct)",
             "Pat. match", "Chessboard", "Char. CAPTCHA", "Word CAPTCHA"))

p.qpm <- function(data)
  ggplot(data, aes(x=task, y=value, colour=type)) +
  geom_boxplot() + scale_y_log10() +
  xlab("Task") + ylab("Queries per minute") +
  scale_colour_manual(legend=FALSE,
                      value=c(interactive="black", automated="gray60")) +
  coord_flip() +
  opts(axis.title.x=theme_blank(), axis.title.y=theme_blank())

doplot("qpm", 5, 3, p.qpm(d.qpm))

# webcam error rate
d.webcam <- read.csv("webcam.csv")
d.webcam$acc <- with(d.webcam, (1 - error.rate) + .05)
d.webcam$scaled <- with(d.webcam, count/sum(count))
p.webcam <- function(data)
  ggplot(data, aes(x=acc, y=scaled)) +
  geom_bar(stat="identity", size=1) +
  scale_x_continuous(limits=c(0,1), formatter="percent") +
  scale_y_continuous(formatter="percent") +
  opts(axis.title.x=theme_blank(), axis.title.y=theme_blank())

doplot("webcam", 4, 4, p.webcam(d.webcam))

# visited link density
d.visited.d <- data.frame(x=d.noninteractive$visited.direct)
p.visited.d <- function(data)
  ggplot(data, aes(x = x/7012)) +
  geom_histogram(binwidth = 2/7012, right = FALSE) +
  scale_x_continuous(formatter="percent", limits=c(0,.02)) +
  ylab("Participant count") +
  opts(axis.title.x=theme_blank())

doplot("visited-d", 4, 4, p.visited.d(d.visited.d))

quit(save="no")
