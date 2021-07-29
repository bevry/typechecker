'use strict'

/** @type {typeof import('./classes.js')} */
const fixtureCompiledClasses = require('./classes-compiled.js')

/** @type {typeof import('./classes.js')} */
let fixtureSourceClasses
try {
	fixtureSourceClasses = require('./classes.js')
	console.log('native classes supported on this environment')
} catch (err) {
	console.log('native classes NOT supported on this environment', err.message)
}

/** @type {typeof import('./async.js')} */
let fixtureSourceAsyncFunction
try {
	fixtureSourceAsyncFunction = require('./async.js')
	console.log('native classes supported on this environment')
} catch (err) {
	console.log('native classes NOT supported on this environment', err.message)
}

/** @type {typeof import('./map.js')} */
let fixtureMap
try {
	fixtureMap = require('./map.js')
	console.log('native Map supported on this environment')
} catch (err) {
	console.log('native Map NOT supported on this environment', err.message)
}

/** @type {typeof import('./map-empty.js')} */
let fixtureMapEmpty
try {
	fixtureMapEmpty = require('./map-empty.js')
	console.log('native Map supported on this environment')
} catch (err) {
	console.log('native Map NOT supported on this environment', err.message)
}

/** @type {typeof import('./weakmap.js')} */
let fixtureWeakMap
try {
	fixtureWeakMap = require('./weakmap.js')
	console.log('native WeakMap supported on this environment')
} catch (err) {
	console.log('native WeakMap NOT supported on this environment', err.message)
}

/** @type {typeof import('./weakmap-empty.js')} */
let fixtureWeakMapEmpty
try {
	fixtureWeakMapEmpty = require('./weakmap-empty.js')
	console.log('native WeakMap supported on this environment')
} catch (err) {
	console.log('native WeakMap NOT supported on this environment', err.message)
}

module.exports = {
	fixtureCompiledClasses,
	fixtureSourceClasses,
	fixtureSourceAsyncFunction,
	fixtureMap,
	fixtureMapEmpty,
	fixtureWeakMap,
	fixtureWeakMapEmpty,
}
