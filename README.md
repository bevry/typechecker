# Balupton's Node.js Utility Functions

This project contains several utility functions used and maintained by Benjamin Lupton


## What it provides

[Take a look at its source file here](https://github.com/balupton/docpad/blob/master/lib/util.coffee#files)


## Installing


1. [Install Node.js](https://github.com/balupton/node/wiki/Installing-Node.js)

2. Install it

		npm install bal-util


## Using

- With Node.js in JavaScript

	``` javascript
	require('coffee-script');
	util = require('bal-util');
	```

- With Node.js in CoffeeScript
	
	``` coffeescript
	util = require 'bal-util'
	```


## History

- v0.7 October 3, 2011
	- Added `versionCompare` and `packageCompare` functions
		- Added `request` dependency

- v0.6 September 14, 2011
	- Updated `util.Group` to support `async` and `sync` grouping

- v0.4 June 2, 2011
	- Added util.type for testing the type of a variable
	- Added util.expandPath and util.expandPaths

- v0.3 June 1, 2011
	- Added util.Group class for your async needs :)

- v0.2 May 20, 2011
	- Added some tests with expresso
	- util.scandir now returns err,list,tree
	- Added util.writetree

- v0.1 May 18, 2011
	- Initial commit


## License

Licensed under the [MIT License](http://creativecommons.org/licenses/MIT/)
Copyright 2011 [Benjamin Arthur Lupton](http://balupton.com)
