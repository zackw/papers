library(ggplot2)

demog <- read.csv("demographics.csv", comment.char="#")
demog$browser <- factor(sub("^Firefox 3$", "Firefox 3.0",
                            sub("(?:\\.0)?\\.[a-zA-Z0-9]+$", "",
                                demog$browser)))

demog$age <- factor(demog$age, ordered=TRUE,
                    levels=c(20,30,50,70),
                    labels=c("18-29","30-49","50-69","70+"))
demog$compuse <- factor(demog$compuse, ordered=TRUE,
                        levels=c(1970,1984,1995,2000,2005),
                        labels=c("Before\n1984", "1984-\n1994",
                          "1994-\n2000",
                          "2000-\n2004", "2005-\npresent"))
demog$netuse <- factor(demog$netuse, ordered=TRUE,
                       levels=c(2005, 2000, 1993, 1982, 1970),
                       labels=c("<1", "1", "2-4", "4-8", "8+"))
# the use of " 1 " here prevents the ordering from getting screwed up
# when melt() merges all the factors, while not interfering with display
demog$computers <- factor(demog$computers, ordered=TRUE,
                          levels=c(0,1,2,3,4,5),
                          labels=c("0"," 1 ","2","3","4","5+"))
demog$website <- factor(demog$website, ordered=TRUE,
                        levels=c("no", "sorta", "amateur", "pro"),
                        labels=c("None", "Dabbling", "Skilled", "Pro"))
demog$mouse <- factor(demog$mouse, ordered=TRUE,
                      levels=c("regular", "touchpad", "trackball",
                        "eraser", "other"),
                      labels=c("Mouse", "Touch\npad", "Track\nball",
                      "Eraser\nhead", "Other"))

demog.u <- melt(subset(demog, TRUE, c("uid","age","compuse","netuse",
                                      "computers","website")),
                id.vars="uid")

levels(demog.u$variable) <- c("Age",
                              "Date of first computer use",
                              "Daily Internet use (hours)",
                              "Number of computers owned",
                              "Web design skill")

pdf("demog.pdf", width=12, height=4)
ggplot(demog.u, aes(x=value)) +
  facet_wrap(~variable, scales='free_x', nrow=1) + geom_bar() +
  scale_y_continuous(breaks=seq(from=0,to=.5,len=4) * 307,
                     labels=c("0%", "16%", "33%", "50%")) +
  opts(axis.title.x=theme_blank(), axis.title.y=theme_blank())
dev.off()
embedFonts("demog.pdf", format="pdfwrite", outfile="../demog.pdf",
   options="-dSubsetFonts=true -dEmbedAllFonts=true -dPDFSETTINGS=/prepress")
system("rm demog.pdf")

pdf("browser.pdf", width=7, height=3.5)
 ggplot(demog, aes(x=browser)) + geom_bar() + coord_flip() +
  opts(axis.title.x=theme_blank(), axis.title.y=theme_blank()) +
  scale_y_continuous(breaks=c(0,.1,.2,.3,.4)*307,
                     labels=c("0%","10%","20%","30%","40%"), expand=c(0.025,0))
dev.off()
embedFonts("browser.pdf", format="pdfwrite", outfile="../browser.pdf",
   options="-dSubsetFonts=true -dEmbedAllFonts=true -dPDFSETTINGS=/prepress")
system("rm browser.pdf")
