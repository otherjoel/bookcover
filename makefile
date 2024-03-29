SHELL = /bin/bash

scribblings/example-cover.png: scribblings/example-cover.rkt
	cd scribblings; racket example-cover.rkt

scribble: scribblings/bookcover.scrbl
scribble: ## Rebuild Scribble docs
	rm -rf scribblings/bookcover/* || true
	cd scribblings && scribble --htmls +m --redirect https://docs.racket-lang.org/local-redirect/ bookcover.scrbl

publish: ## Sync Scribble HTML docs to web server (doesn’t rebuild anything)
	rsync -av --delete scribblings/bookcover/ $(JDCOM_SRV)what-about/bookcover/

png: ## Update the example-cover.png file
png: scribblings/example-cover.png

.PHONY: scribble publish png zap help

zap: ## Deletes Racket caches and all scribble output
	rm *.rkt~; \
	rm -rf compiled; \
	rm -rf scribblings/compiled; \
	find scribblings -type f ! \( -name '*.scrbl' -o -name '*.rkt' \) -delete

# Self-documenting make file (http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html)
help: ## Displays this help screen
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
