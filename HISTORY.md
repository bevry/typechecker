# History

## v4.0.0 September 21, 2015
- Added new `map` and `weakmap` types that the `getType` method can now return
- Added the methods:
 	- `isMap` (checks for Map instance)
	- `isWeakMap` (checks for WeakMap instance)

## v3.0.0 August 27, 2015
- Added new `class` type that the `getType` method can now return
- Added the methods:
 	- `isClass` (checks for native and conventional classes)
	- `isNativeClass` (checks for native ES6 classes)
	- `isConventionalClass` (checks for functions that start with a capital letter)
- Anonymous compiled/non-native classes may be detected as functions instead of as classes. If you rely on class detection, be aware of this, and document this to your users accordingly.

## v2.1.0 August 26, 2015
- Fixed `isEmpty` - it use to return the opposite of what was empty
- Converted from CoffeeScript to ES6+
- Updated base files
- Everything is now tested thoroughly

## v2.0.8 November 1, 2013
- Dropped component.io and bower support, just use ender or browserify

## v2.0.7 October 27, 2013
- Re-packaged

## v2.0.6 September 18, 2013
- Fixed node release (since v2.0.5)
- Fixed bower release (since v2.0.4)

## v2.0.5 September 18, 2013
- Fixed node release (since v2.0.4)

## v2.0.4 September 18, 2013
- Fixed cyclic dependency problem on windows (since v2.0.3)
- Added bower support

## v2.0.3 September 18, 2013
- Attempt at fixing circular dependency infinite loop (since v2.0.2)

## v2.0.2 September 18, 2013
- Added component.io support

## v2.0.1 March 27, 2013
- Fixed some package.json properties

## v2.0.0 March 27, 2013
- Split typeChecker from [bal-util](https://github.com/balupton/bal-util)
