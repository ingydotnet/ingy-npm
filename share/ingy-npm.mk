.PHONY: npm doc test

INGY_NPM := ../ingy-npm

export PATH := $(PWD)/node_modules/.bin:$(PATH)

ifeq ($(wildcard Meta),)
    $(error Meta file is required)
endif

NAME := $(shell grep '^name: ' Meta 2>/dev/null | cut -d' ' -f2)
VERSION := $(shell grep '^version: ' Meta 2>/dev/null | cut -d' ' -f2)
DISTDIR := $(NAME)-$(VERSION)
DIST := $(DISTDIR).tgz

ALL_LIB_DIR := $(shell find lib -type d)
ALL_NPM_DIR := $(ALL_LIB_DIR:%=npm/%)
ALL_COFFEE := $(shell find lib -name *.coffee)
ALL_NPM_JS := $(ALL_COFFEE:%.coffee=npm/%.js)

NODE_MODULES := \
    $(INGY_NPM) \
    coffeescript \
    js-yaml \
    $(shell jyj Meta | jq -r '(.["=npm"].dependencies // {}) + (.["=npm"].devDependencies // {}) | keys | .[]')

    # pkg \

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
	@echo "    make publish-dryrun   - Don't actually push to NPM"
	@echo ''

node_modules:
	mkdir $@
	rm -f package*
	npm init --yes > /dev/null
	npm install --no-save $(NODE_MODULES)
	rm -f package*

ingy-npm-test:
	coffee -e '(require "./test/lib/test/harness").run()' $@/*.coffee

install: distdir
	npm install -g $(DISTDIR)

doc:
	swim --to=pod --complete --wrap doc/$(NAME).swim > ReadMe.pod

npm: node_modules
	node_modules/.bin/ingy-npm-make-npm

dist: npm
	(cd npm; npm pack)
	mv npm/$(DIST) .

distdir: dist
	tar xzf $(DIST)
	mv package $(DISTDIR)

disttest: distdir
	(cd $(DISTDIR); npm test) && rm -fr npm

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
	rm -f package*
	rm -fr npm node_modules
	rm -f $(DIST)
	rm -fr $(DISTDIR)

#------------------------------------------------------------------------------
check-release: node_modules
	node_modules/.bin/ingy-npm-check-release
