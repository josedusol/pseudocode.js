.PHONY: all build clean docs default lint release setup

VERSION=2.1.1

# Building tools
BROWSERIFY = $(realpath ./node_modules/.bin/browserify)
CLEANCSS = $(realpath ./node_modules/.bin/cleancss)
ESLINT = $(realpath ./node_modules/.bin/eslint)
WATCHIFY = $(realpath ./node_modules/.bin/watchify)
UGLIFYJS = $(realpath ./node_modules/.bin/uglifyjs) \
	--mangle \
	--beautify \
	ascii_only=true,beautify=false

SAMPLES = build/katex-samples.html build/mathjax-v2-samples.html build/mathjax-v3-samples.html


default: build


all : clean build docs release


setup: static/katex/
	npm install
	@echo "> Node.js packages installed"

static/katex/:
	@rm -rf static/katex
	cd static && wget https://github.com/Khan/KaTeX/releases/download/v0.11.1/katex.zip && unzip katex.zip
	@rm -rf static/katex.zip
	@echo "> Katex downloaded"



watch-js: pseudocode.js $(wildcard src/*.js)
	$(WATCHIFY) $< --standalone pseudocode -o build/pseudocode.js



build: build/pseudocode.js build/pseudocode.css $(SAMPLES)
	@echo "> Building succeeded"

build/pseudocode.js: pseudocode.js $(wildcard src/*.js)
	@$(MAKE) --no-print-directory lint
	$(BROWSERIFY) $< --exclude mathjax --exclude katex --standalone pseudocode -o $@

lint: pseudocode.js $(wildcard src/*.js)
	$(ESLINT) $^

build/pseudocode.css: static/pseudocode.css
	cp static/pseudocode.css build/pseudocode.css

build/%-samples.html: static/%.html.part static/body.html.part static/footer.html.part
	cat $^ > $@



release: build docs build/pseudocode-js.tar.gz build/pseudocode-js.zip
	@echo "> Release package generated"

RELEASE_DIR=pseudocode.js-$(VERSION)/
build/pseudocode-js.tar.gz: build/$(RELEASE_DIR)
	cd build && tar czf pseudocode-js.tar.gz $(RELEASE_DIR)

build/pseudocode-js.zip: build/$(RELEASE_DIR)
	cd build && zip -rq pseudocode-js.zip $(RELEASE_DIR)

build/$(RELEASE_DIR): build/pseudocode.js build/pseudocode.min.js build/pseudocode.css build/pseudocode.min.css $(SAMPLES) README.md
	mkdir -p build/$(RELEASE_DIR)
	cp -r $^ build/$(RELEASE_DIR)

build/pseudocode.min.js: build/pseudocode.js
	$(UGLIFYJS) < $< > $@

build/pseudocode.min.css: build/pseudocode.css
	$(CLEANCSS) -o $@ $<



docs: build/pseudocode.min.js build/pseudocode.min.css $(SAMPLES)
	cp build/pseudocode.min.css docs/pseudocode.css
	cp build/pseudocode.min.js docs/pseudocode.js
	cp $(SAMPLES) docs/



clean:
	@rm -rf build/*