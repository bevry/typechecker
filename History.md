## History

- v1.5.0 April 18, 2012
	- `balUtilPaths` changes:
		- `scan` was removed, not sure what it was used for
		- `isDirectory` now returns the `fileStat` argument to the callback
		- `scandir` changes:
			- `ignorePatterns` option when set to true now uses the new `balUtilPaths.commonIgnorePatterns` property
			- fixed error throwing when passed an invalid path
			- now supports a new `stat` option
			- will return the `fileStat` argument to the `fileAction` and `dirAction` callbacks
			- `ignorePatterns` and `ignoreHiddenFiles` will now correctly be passed to child scandir calls
		- `cpdir` and `rpdir` now uses `path.join` and support `ignoreHiddenFiles` and `ignorePatterns`
		- `writetree` now uses `path.join`

- v1.4.3 April 14, 2012
	- CoffeeScript dependency is now bundled
	- Fixed incorrect octal `0700` should have been `700`

- v1.4.2 April 5, 2012
	- Fixed a failing test due to the `bal-util.npm` to `bal-util` rename
	- Improvements to `balUtilModules.spawn`
		- will only return an error if the exit code was `1`
		- will also contain the `code` and `signal` with the results
		- `results[x][0]` is now the stderr string, rather than an error object

- v1.4.1 April 5, 2012
	- Added `spawn` to `balUtilModules`
	- Added `ignoreHiddenFiles` option to `balUtilPaths.scandir`

- v1.4.0 April 2, 2012
	- Renamed `balUtilGroups` to `balUtilFlow`
	- Added `toString`, `isArray` and `each` to `balUtilFlow`
	- Added `rpdir`, `empty`, and `isPathOlderThan` to `balUtilPaths`

- v1.3.0 February 26, 2012
	- Added `openFile` and `closeFile` to open and close files safely (always stays below the maximum number of allowed open files)
	- Updated all path utilities to use `openFile` and `closeFile`
	- Added npm scripts

- v1.2.0 February 14, 2012
	- Removed single and multi modes from `exec`, now always returns the same consistent `callback(err,results)` instead

- v1.1.0 February 6, 2012
	- Modularized
	- Added [docco](http://jashkenas.github.com/docco/) docs

- v1.0 February 5, 2012
	- Moved unit tests to [Mocha](http://visionmedia.github.com/mocha/)
		- Offers more flexible unit testing
		- Offers better guarantees that tests actually ran, and that they actually ran correctly
	- Added `readPath` and `scantree`
	- Added `readFiles` option to `scandir`
	- `scandir` now supports arguments in object format
	- Removed `parallel`
	- Tasks inside groups now are passed `next` as there only argument
	- Removed `resolvePath`, `expandPath` and `expandPaths`, they were essentially the same as `path.resolve`
	- Most functions will now chain
	- `comparePackage` now supports comparing two local, or two remote packages
	- Added `gitPull`

- v0.9 January 18, 2012
	- Added `exec`, `initNodeModules`, `initGitSubmodules`, `EventSystem.when`
	- Added support for no callbacks

- v0.8 November 2, 2011
	- Considerable improvements to `scandir`, `cpdir` and `rmdir`
		- Note, passing `false` as the file or dir actions will now skip all of that type. Pass `null` if you do not want that.
		- `dirAction` is now fired before we read the directories children, if you want it to fire after then in the next callback, pass a callback in the 3rd argument. See `rmdir` for an example of this.
	- Fixed npm web to url warnings

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
