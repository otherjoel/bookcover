SHELL = /bin/bash

scribblings/example-cover.pdf: scribblings/example-cover.rkt
	cd scribblings && racket -r example-cover.rkt

scribblings/example-cover.png: scribblings/example-cover.pdf
	sips -s format png --out scribblings/example-cover.png scribblings/example-cover.pdf

all: ## Update all targets
all: scribblings/example-cover.png

.PHONY: all zap help

zap: ## Deletes Racket caches and all scribble output
	rm *.rkt~; \
	rm -rf compiled; \
	rm -rf scribblings/compiled; \
	find scribblings -type f ! \( -name '*.scrbl' -o -name '*.rkt' \) -delete

# Self-documenting make file (http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html)
help: ## Displays this help screen
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help