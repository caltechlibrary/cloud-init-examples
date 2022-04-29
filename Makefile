#
# A simple Makefile for generating a documentation site based on 
# the Markdown documents and plain Pandoc.
#

PROJECT = cloud-init-examples

VERSION = $(shell grep '"version":' codemeta.json | cut -d\"  -f 4)

BRANCH = $(shell git branch | grep '* ' | cut -d\  -f 2)

MARKDOWN_PAGES =$(shell ls -1 *.md | sed -E 's/\.md//g')

HTML_PAGES = $(shell ls -1 *.md | sed -E 's/\.md/.html/g')


build: $(HTML_PAGES) CITATION.cff

CITATION.cff: codemeta.json
	codemeta2cff


$(HTML_PAGES): $(MARKDOWN_PAGES)

$(MARKDOWN_PAGES): .FORCE
	pandoc -s --metadata title:"Multipass and Cloud Init Examples" $@.md > $@.html

status:
	git status

save:
	@if [ "$(msg)" != "" ]; then git commit -am "$(msg)"; else git commit -am "Quick Save"; fi
	git push origin $(BRANCH)

refresh:
	git fetch origin
	git pull origin $(BRANCH)

clean: 
	@rm *.html 2>&1

.FORCE:
