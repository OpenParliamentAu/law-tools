test:

	NODE_PATH='' nodemon \
	  -e 'pegjs|coffee' \
	  --watch test \
	  --watch . \
	  node_modules/.bin/mocha \
    $(arg)

.PHONY: test
