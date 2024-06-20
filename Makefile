#
# A simple Makefile for generating a documentation site based on 
# the Markdown documents and Pandoc.
#

PROJECT = cloud-init-examples

VERSION = $(shell grep '"version":' codemeta.json | cut -d\"  -f 4)

RELEASE_HASH=$(shell git log --pretty=format:'%h' -n 1)

BRANCH = $(shell git branch | grep '* ' | cut -d\  -f 2)

MARKDOWN_PAGES =$(shell ls -1 *.md drafts/*.md | sed -E 's/\.md//g')

HTML_PAGES = $(shell ls -1 *.md | sed -E 's/\.md/.html/g')

build: CITATION.cff about.md $(HTML_PAGES) index.html about.html

CITATION.cff: codemeta.json
	@cat codemeta.json | sed -E   's/"@context"/"at__context"/g;s/"@type"/"at__type"/g;s/"@id"/"at__id"/g' >_codemeta.json
	echo "" | pandoc --metadata title="Cite $(PROGRAM)" --metadata-file=_codemeta.json --template=codemeta-cff.tmpl >CITATION.cff

about.html: about.md

about.md: codemeta.json .FORCE
	cat codemeta.json | sed -E 's/"@context"/"at__context"/g;s/"@type"/"at__type"/g;s/"@id"/"at__id"/g' >_codemeta.json
	echo "" | pandoc --metadata-file=_codemeta.json --template codemeta-md.tmpl >about.md 2>/dev/null
	if [ -f _codemeta.json ]; then rm _codemeta.json; fi

index.html: README.md $(MARKDOWN_PAGES)
	mv README.html index.html

$(HTML_PAGES): $(MARKDOWN_PAGES)

$(MARKDOWN_PAGES): .FORCE
	pandoc -s --metadata title:"Multipass and Cloud Init Examples" \
		--template page.tmpl \
		$@.md > $@.html

status:
	git status

save:
	@if [ "$(msg)" != "" ]; then git commit -am "$(msg)"; else git commit -am "Quick Save"; fi
	git push origin $(BRANCH)

publish: save
	-git checkout gh-pages
	-git pull origin $(BRANCH)
	- make -f website.mak
	-git commit -am "publishing website"
	-git push origin gh-pages
	git checkout $(BRANCH)

refresh:
	git fetch origin
	git pull origin $(BRANCH)

clean: 
	@rm *.html 2>&1

.FORCE:
