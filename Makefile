PROJECT=css

all: pdf

show: pdf
	start $(PROJECT).pdf

pdf:
	pdflatex $(PROJECT)
	bibtex $(PROJECT)
	pdflatex $(PROJECT)
	bibtex $(PROJECT)
	pdflatex $(PROJECT)
#	dvips -t letter -Ppdf $(PROJECT).dvi
#	ps2pdf $(PROJECT).ps

clean:
	rm -f $(PROJECT).dvi $(PROJECT).aux $(PROJECT).bbl $(PROJECT).blg $(PROJECT).log
