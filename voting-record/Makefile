main:

	NODE_PATH='..' iced index.coffee $(arg)

watch:

	NODE_PATH='..' nodemon -x iced index.coffee $(arg)

test:

	NODE_PATH='..' nodemon \
	  -e 'pegjs|coffee' \
	  --watch test \
	  --watch . \
	  node_modules/.bin/mocha \
    $(arg)

.PHONY: main test watch
