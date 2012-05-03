# If you change something here, be sure to change it in package.json's scripts as well

dev:
	coffee -w -o lib/ -c src/

test:
	node ./node_modules/mocha/bin/mocha

docs:
	./node_modules/.bin/docco lib/*.coffee

.PHONY: dev test docs