# If you change something here, be sure to change it in package.json's scripts as well

dev:
	./node_modules/.bin/coffee -w -o lib/ -c src/

compile:
	./node_modules/.bin/coffee -o lib/ -c src/

docs:
	./node_modules/.bin/docco src/*.coffee

test:
	node ./node_modules/mocha/bin/mocha

.PHONY: dev compile docs test