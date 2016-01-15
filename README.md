<!-- TITLE/ -->

<h1>TypeChecker</h1>

<!-- /TITLE -->


<!-- BADGES/ -->

<span class="badge-travisci"><a href="http://travis-ci.org/bevry/typechecker" title="Check this project's build status on TravisCI"><img src="https://img.shields.io/travis/bevry/typechecker/master.svg" alt="Travis CI Build Status" /></a></span>
<span class="badge-npmversion"><a href="https://npmjs.org/package/typechecker" title="View this project on NPM"><img src="https://img.shields.io/npm/v/typechecker.svg" alt="NPM version" /></a></span>
<span class="badge-npmdownloads"><a href="https://npmjs.org/package/typechecker" title="View this project on NPM"><img src="https://img.shields.io/npm/dm/typechecker.svg" alt="NPM downloads" /></a></span>
<span class="badge-daviddm"><a href="https://david-dm.org/bevry/typechecker" title="View the status of this project's dependencies on DavidDM"><img src="https://img.shields.io/david/bevry/typechecker.svg" alt="Dependency Status" /></a></span>
<span class="badge-daviddmdev"><a href="https://david-dm.org/bevry/typechecker#info=devDependencies" title="View the status of this project's development dependencies on DavidDM"><img src="https://img.shields.io/david/dev/bevry/typechecker.svg" alt="Dev Dependency Status" /></a></span>
<br class="badge-separator" />
<span class="badge-slackin"><a href="https://slack.bevry.me" title="Join this project's slack community"><img src="https://slack.bevry.me/badge.svg" alt="Slack community badge" /></a></span>
<span class="badge-patreon"><a href="http://patreon.com/bevry" title="Donate to this project using Patreon"><img src="https://img.shields.io/badge/patreon-donate-yellow.svg" alt="Patreon donate button" /></a></span>
<span class="badge-gratipay"><a href="https://www.gratipay.com/bevry" title="Donate weekly to this project using Gratipay"><img src="https://img.shields.io/badge/gratipay-donate-yellow.svg" alt="Gratipay donate button" /></a></span>
<span class="badge-flattr"><a href="https://flattr.com/profile/balupton" title="Donate to this project using Flattr"><img src="https://img.shields.io/badge/flattr-donate-yellow.svg" alt="Flattr donate button" /></a></span>
<span class="badge-paypal"><a href="https://bevry.me/paypal" title="Donate to this project using Paypal"><img src="https://img.shields.io/badge/paypal-donate-yellow.svg" alt="PayPal donate button" /></a></span>
<span class="badge-bitcoin"><a href="https://bevry.me/bitcoin" title="Donate once-off to this project using Bitcoin"><img src="https://img.shields.io/badge/bitcoin-donate-yellow.svg" alt="Bitcoin donate button" /></a></span>
<span class="badge-wishlist"><a href="https://bevry.me/wishlist" title="Buy an item on our wishlist for us"><img src="https://img.shields.io/badge/wishlist-donate-yellow.svg" alt="Wishlist browse button" /></a></span>

<!-- /BADGES -->


<!-- DESCRIPTION/ -->

Utilities to get and check variable types (isString, isPlainObject, isRegExp, etc)

<!-- /DESCRIPTION -->


## Why?

Why should I use this instead of say `instanceof`?

Under certain circumstances `instanceof` may not return the correct results. This occurs with [node's vm module](http://nodejs.org/api/vm.html#vm_globals) especially, and circumstances where an object's prototype has been dereferenced from the original. As such, for basic `==` and `===` checks (like `a === null`), you're fine not using this, but for checks when you would have done `instanceof` (like `err instanceof Error`), you should try to use this instead. Plus things like `isEmpty`, `isEmptyObject` and `isPlainObject` are darn useful!


<!-- INSTALL/ -->

<h2>Install</h2>

<a href="https://npmjs.com" title="npm is a package manager for javascript"><h3>NPM</h3></a><ul>
<li>Install: <code>npm install --save typechecker</code></li>
<li>Use: <code>require('typechecker')</code></li></ul>

<a href="http://browserify.org" title="Browserify lets you require('modules') in the browser by bundling up all of your dependencies"><h3>Browserify</h3></a><ul>
<li>Install: <code>npm install --save typechecker</code></li>
<li>Use: <code>require('typechecker')</code></li>
<li>CDN URL: <code>//wzrd.in/bundle/typechecker@4.1.0</code></li></ul>

<a href="http://enderjs.com" title="Ender is a full featured package manager for your browser"><h3>Ender</h3></a><ul>
<li>Install: <code>ender add typechecker</code></li>
<li>Use: <code>require('typechecker')</code></li></ul>

<!-- /INSTALL -->


## Usage

### Example

``` javascript
require('typechecker').isRegExp(/^a/)  // returns true
```

### Methods

Helpers:

- `getObjectType` - returns the object string of the value, e.g. when passed `/^a/` it'll return `"[object RegExp]"`
- `getType` - returns lower case string of the type, e.g. when passed `/^a/` it'll return `"regex"`

Values:

- `isPlainObject` - returns `true` if the value doesn't have a custom prototype
- `isEmpty` - returns `true` if the value is `null` or `undefined`
- `isEmptyObject` - returns `true` if the object has no keys that are its own
- `isNativeClass` - returns `true` if the value is a native ES6 class
- `isConventionalClass` - returns `true` if the value is a function which name starts with a capital letter

Types:

- `isError` - returns `true` if the value is an error, otherwise `false`
- `isDate` - returns `true` if the value is a date, otherwise `false`
- `isArguments` - returns `true` if the value is function arguments, otherwise `false`
- `isClass` - returns `true` if the value is a native or conventional class, otherwise `false`
- `isFunction` - returns `true` if the value is a function, otherwise `false`
- `isRegExp` - returns `true` if the value is a regular expression instance, otherwise `false`
- `isArray` - returns `true` if the value is an array, otherwise `false`
- `isNumber` - returns `true` if the value is a number (`"2"` is a string), otherwise `false`
- `isString` - returns `true` if the value is a string, otherwise `false`
- `isBoolean` - returns `true` if the value is a boolean, otherwise `false`
- `isNull` - returns `true` if the value is null, otherwise `false`
- `isUndefined` - returns `true` if the value is undefined, otherwise `false`


<!-- HISTORY/ -->

<h2>History</h2>

<a href="https://github.com/bevry/typechecker/blob/master/HISTORY.md#files">Discover the release history by heading on over to the <code>HISTORY.md</code> file.</a>

<!-- /HISTORY -->


<!-- CONTRIBUTE/ -->

<h2>Contribute</h2>

<a href="https://github.com/bevry/typechecker/blob/master/CONTRIBUTING.md#files">Discover how you can contribute by heading on over to the <code>CONTRIBUTING.md</code> file.</a>

<!-- /CONTRIBUTE -->


<!-- BACKERS/ -->

<h2>Backers</h2>

<h3>Maintainers</h3>

These amazing people are maintaining this project:

<ul><li><a href="http://balupton.com">Benjamin Lupton</a> — <a href="https://github.com/bevry/typechecker/commits?author=balupton" title="View the GitHub contributions of Benjamin Lupton on repository bevry/typechecker">view contributions</a></li></ul>

<h3>Sponsors</h3>

No sponsors yet! Will you be the first?

<span class="badge-patreon"><a href="http://patreon.com/bevry" title="Donate to this project using Patreon"><img src="https://img.shields.io/badge/patreon-donate-yellow.svg" alt="Patreon donate button" /></a></span>
<span class="badge-gratipay"><a href="https://www.gratipay.com/bevry" title="Donate weekly to this project using Gratipay"><img src="https://img.shields.io/badge/gratipay-donate-yellow.svg" alt="Gratipay donate button" /></a></span>
<span class="badge-flattr"><a href="https://flattr.com/profile/balupton" title="Donate to this project using Flattr"><img src="https://img.shields.io/badge/flattr-donate-yellow.svg" alt="Flattr donate button" /></a></span>
<span class="badge-paypal"><a href="https://bevry.me/paypal" title="Donate to this project using Paypal"><img src="https://img.shields.io/badge/paypal-donate-yellow.svg" alt="PayPal donate button" /></a></span>
<span class="badge-bitcoin"><a href="https://bevry.me/bitcoin" title="Donate once-off to this project using Bitcoin"><img src="https://img.shields.io/badge/bitcoin-donate-yellow.svg" alt="Bitcoin donate button" /></a></span>
<span class="badge-wishlist"><a href="https://bevry.me/wishlist" title="Buy an item on our wishlist for us"><img src="https://img.shields.io/badge/wishlist-donate-yellow.svg" alt="Wishlist browse button" /></a></span>

<h3>Contributors</h3>

These amazing people have contributed code to this project:

<ul><li><a href="http://balupton.com">Benjamin Lupton</a> — <a href="https://github.com/bevry/typechecker/commits?author=balupton" title="View the GitHub contributions of Benjamin Lupton on repository bevry/typechecker">view contributions</a></li>
<li><a href="https://github.com/joegesualdo">Joe Gesualdo</a> — <a href="https://github.com/bevry/typechecker/commits?author=joegesualdo" title="View the GitHub contributions of Joe Gesualdo on repository bevry/typechecker">view contributions</a></li>
<li><a href="http://seanfridman.com">Sean Fridman</a> — <a href="https://github.com/bevry/typechecker/commits?author=sfrdmn" title="View the GitHub contributions of Sean Fridman on repository bevry/typechecker">view contributions</a></li></ul>

<a href="https://github.com/bevry/typechecker/blob/master/CONTRIBUTING.md#files">Discover how you can contribute by heading on over to the <code>CONTRIBUTING.md</code> file.</a>

<!-- /BACKERS -->


<!-- LICENSE/ -->

<h2>License</h2>

Unless stated otherwise all works are:

<ul><li>Copyright &copy; 2013+ <a href="http://bevry.me">Bevry Pty Ltd</a></li>
<li>Copyright &copy; 2011-2012 <a href="http://balupton.com">Benjamin Lupton</a></li></ul>

and licensed under:

<ul><li><a href="http://spdx.org/licenses/MIT.html">MIT License</a></li></ul>

<!-- /LICENSE -->
