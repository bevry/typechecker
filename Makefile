# For Component.io

build: components index.js
	npm install
	./node_modules/.bin/cake compile
	@component build --dev

components: component.json
	@component install --dev

clean:
	rm -fr build components template.js

.PHONY: clean
