.PHONY: npm doc test

INGY_NPM := ../ingy-npm

export PATH := $(PWD)/node_modules/.bin:$(PATH)

ifeq ($(wildcard Meta),)
    $(error Meta file is required)
endif

NAME := $(shell grep '^name: ' Meta 2>/dev/null | cut -d' ' -f2)
VERSION := $(shell grep '^version: ' Meta 2>/dev/null | cut -d' ' -f2)
DISTDIR := $(NAME)-$(VERSION)
DIST := $(DISTDIR).tar.gz

ALL_LIB_DIR := $(shell find lib -type d)
ALL_NPM_DIR := $(ALL_LIB_DIR:%=npm/%)
ALL_COFFEE := $(shell find lib -name *.coffee)
ALL_NPM_JS := $(ALL_COFFEE:%.coffee=npm/%.js)

NODE_MODULES := \
    $(INGY_NPM) \
    coffeescript \
    js-yaml \
    pkg \
    $(shell jyj Meta | jq -r '(.["=npm"].dependencies // {}) + (.["=npm"].devDependencies // {}) | keys | .[]')

default: help

help:
	@echo ''
	@echo 'Makefile targets:'
	@echo ''
	@echo '    make test     - Run the repo tests'
	@echo '    make install  - Install the repo'
	@echo '    make doc      - Make the docs'
	@echo ''
	@echo '    make npm      - Make npm/ dir for Node'
	@echo '    make dist     - Make NPM distribution tarball'
	@echo '    make distdir  - Make NPM distribution directory'
	@echo '    make disttest - Run the dist tests'
	@echo '    make publish  - Publish the dist to NPM'
	@echo '    make publish-dryrun   - Don'"'"'t actually push to NPM'
	@echo ''

node_modules:
	mkdir $@
	npm init --yes > /dev/null
	npm install --no-save $(NODE_MODULES)
	rm -f package*

ingy-npm-test:
	coffee -e '(require "./test/lib/test/harness").run()' $@/*.coffee

install: distdir
	(cd $(DISTDIR); npm install -g .)
	rm -fr npm

doc:
	swim --to=pod --complete --wrap doc/$(NAME).swim > ReadMe.pod

npm: node_modules
	node_modules/.bin/ingy-npm-make-npm

dist: npm
	(cd npm; dzil build)
	mv npm/$(DIST) .
	rm -fr npm

distdir: npm
	(cd npm; dzil build)
	mv npm/$(DIST) .
	tar xzf $(DIST)
	rm -fr npm $(DIST)

disttest: npm
	(cd npm; dzil test) && rm -fr npm

publish: check-release dist
	npm publish $(DIST)
	git tag $(VERSION)
	git push --tag
	rm $(DIST)

publish-dryrun: check-release dist
	echo npm publish $(DIST)
	echo git tag $(VERSION)
	echo git push --tag
	rm $(DIST)

ingy-npm-clean:
	rm -fr npm $(DIST) $(DISTDIR)

#------------------------------------------------------------------------------
check-release:
	ingy-npm-check-release
