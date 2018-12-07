/* @flow */
/* eslint no-console:0, space-before-keywords:0, no-undefined:0, no-magic-numbers:0, new-cap:0, no-eval:0 */
'use strict'

// Import
const path = require('path')
const { equal, inspect } = require('assert-helpers')
const { suite } = require('kava')
const typeChecker = require('./index.js')

// Environment
const fixtureCompiledClasses = require(path.resolve(
	__dirname,
	'..',
	'edition-node-0.8',
	'fixtures',
	'classes.js'
))
let fixtureSourceClasses, fixtureSourceAsyncFunction, fixtureMap, fixtureWeakMap
try {
	fixtureSourceClasses = require(path.resolve(
		__dirname,
		'..',
		'source',
		'fixtures',
		'classes.js'
	))
	console.log('native classes supported on this environment')
} catch (err) {
	console.log('native classes NOT supported on this environment', err.message)
}
try {
	fixtureSourceAsyncFunction = require(path.resolve(
		__dirname,
		'..',
		'source',
		'fixtures',
		'async.js'
	))
	console.log('native classes supported on this environment')
} catch (err) {
	console.log('native classes NOT supported on this environment', err.message)
}
try {
	fixtureMap = require(path.resolve(
		__dirname,
		'..',
		'source',
		'fixtures',
		'map.js'
	))
	console.log('native Map supported on this environment')
} catch (err) {
	console.log('native Map NOT supported on this environment', err.message)
}
try {
	fixtureWeakMap = require(path.resolve(
		__dirname,
		'..',
		'source',
		'fixtures',
		'weakmap.js'
	))
	console.log('native WeakMap supported on this environment')
} catch (err) {
	console.log('native WeakMap NOT supported on this environment', err.message)
}

// Types
suite('typechecker', function(suite, test) {
	suite('value', function(suite, test) {
		test('isObject', function() {
			equal(typeChecker.isObject({}), true, 'object {} should be a object')
			equal(typeChecker.isObject(null), false, 'null should not be a object')
			equal(typeChecker.isObject('a'), false, 'string should not be a object')
			equal(
				typeChecker.isObject(''),
				false,
				'empty string should not be a object'
			)
			equal(typeChecker.isObject(), false, 'undefined should not be a object')
		})

		test('isPlainObject', function() {
			equal(
				typeChecker.isPlainObject({}),
				true,
				'object {} should be a plain object'
			)
			equal(
				typeChecker.isPlainObject(null),
				false,
				'null should not be a plain object'
			)
			equal(
				typeChecker.isPlainObject('a'),
				false,
				'string should not be a plain object'
			)
			equal(
				typeChecker.isPlainObject(''),
				false,
				'empty string should not be a plain object'
			)
			equal(
				typeChecker.isPlainObject(),
				false,
				'undefined should not be a plain object'
			)
			if (fixtureSourceClasses) {
				equal(
					typeChecker.isPlainObject(new fixtureSourceClasses.A()),
					false,
					'native clas instantiation should not be a plain object'
				)
			}
			equal(
				typeChecker.isPlainObject(new fixtureCompiledClasses.A()),
				false,
				'conventional class instantiation should not be a plain object'
			)
		})

		test('isEmpty', function() {
			equal(typeChecker.isEmpty(null), true, 'null should be considered empty')
			equal(typeChecker.isEmpty(), true, 'undefined should be considered empty')
			equal(
				typeChecker.isEmpty(false),
				false,
				'false should not be considered empty'
			)
			equal(typeChecker.isEmpty(0), false, '0 should not be considered empty')
			equal(typeChecker.isEmpty(''), false, '"" should not be considered empty')
			equal(typeChecker.isEmpty({}), false, '{} should not be considered empty')
		})

		suite('isEmptyObject', function(suite, test) {
			suite('primatives', function(suite, test) {
				test('empty object', function() {
					equal(
						typeChecker.isEmptyObject({}),
						true,
						'{} should be considered empty'
					)
				})
				if (fixtureMap) {
					test('map', function() {
						equal(
							typeChecker.isEmptyObject(fixtureMap),
							true,
							'new Map() should be considered empty'
						)
					})
				}
				if (fixtureWeakMap) {
					test('weakmap', function() {
						equal(
							typeChecker.isEmptyObject(fixtureWeakMap),
							true,
							'new WeakMap() should be considered empty'
						)
					})
				}
				test('non-empty object', function() {
					equal(
						typeChecker.isEmptyObject({ a: 1 }),
						false,
						'{a: 1} should not be considered empty'
					)
				})
			})

			test('native classes', function() {
				if (!fixtureSourceClasses) {
					console.log(
						'skipping checks as native classes not supported on this environment'
					)
					return
				}
				equal(
					typeChecker.isEmptyObject(new fixtureSourceClasses.A()),
					true,
					'class A instantiation should be considered empty'
				)
				equal(
					typeChecker.isEmptyObject(new fixtureSourceClasses.D()),
					true,
					'class D instantiation should not be considered empty'
				)
				equal(
					typeChecker.isEmptyObject(new fixtureSourceClasses.E()),
					true,
					'class E instantiation should be considered empty'
				)
				equal(
					typeChecker.isEmptyObject(new fixtureSourceClasses.F()),
					false,
					'class F instantiation should not be considered empty'
				)
			})
			test('conventional classes', function() {
				equal(
					typeChecker.isEmptyObject(new fixtureCompiledClasses.A()),
					true,
					'class A instantiation should be considered empty'
				)
				equal(
					typeChecker.isEmptyObject(new fixtureCompiledClasses.D()),
					true,
					'class D instantiation should not be considered empty'
				)
				equal(
					typeChecker.isEmptyObject(new fixtureCompiledClasses.E()),
					true,
					'class E instantiation should be considered empty'
				)
				equal(
					typeChecker.isEmptyObject(new fixtureCompiledClasses.F()),
					false,
					'class F instantiation should not be considered empty'
				)
			})
		})

		test('isNativeClass', function() {
			if (!fixtureSourceClasses) {
				console.log(
					'skipping checks as native classes not supported on this environment'
				)
				return
			}
			equal(
				typeChecker.isNativeClass(fixtureSourceClasses.A),
				true,
				'class A {} should be considered native class'
			)
			equal(
				typeChecker.isNativeClass(fixtureSourceClasses.b),
				true,
				'class {} should be considered native class'
			)
			equal(
				typeChecker.isNativeClass(fixtureSourceClasses.C),
				true,
				'class C extends A {} should be considered native class'
			)
			equal(
				typeChecker.isNativeClass(function() {}),
				false,
				'function () {} should not be considered native class'
			)
		})

		test('isConventionalClass', function() {
			equal(
				typeChecker.isConventionalClass(fixtureCompiledClasses.A),
				true,
				'compiled class A {} should be considered conventional class'
			)
			equal(
				typeChecker.isConventionalClass(fixtureCompiledClasses.a),
				false,
				'compiled class a {} should not be considered conventional class'
			)
			equal(
				typeChecker.isConventionalClass(fixtureCompiledClasses.b),
				false,
				'compiled class {} should not be considered conventional class'
			)
			equal(
				typeChecker.isConventionalClass(fixtureCompiledClasses.C),
				true,
				'compiled class C extends A {} should not be considered conventional class'
			)
			equal(
				typeChecker.isConventionalClass(function B() {}),
				true,
				'function B () {} should be considered conventional class'
			)
			equal(
				typeChecker.isConventionalClass(function b() {}),
				false,
				'function b () {} should not be considered conventional class'
			)
			equal(
				typeChecker.isConventionalClass(function() {}),
				false,
				'function () {} should not be considered conventional class'
			)
			equal(
				typeChecker.isConventionalClass(eval('(function(BasePlugin){})')),
				false,
				'function(BasePlugin){} should not be considered conventional class'
			)
		})

		test('isAsyncFunction', function() {
			if (!fixtureSourceAsyncFunction) {
				console.log(
					'skipping checks as native async functions not supported on this environment'
				)
				return
			}
			equal(
				typeChecker.isAsyncFunction(fixtureSourceAsyncFunction),
				true,
				'async function AsyncFunction () {} should be considered an async function'
			)
			equal(
				typeChecker.isSyncFunction(fixtureSourceAsyncFunction),
				false,
				'async function AsyncFunction () {} should not be considered a sync function'
			)
			equal(
				typeChecker.isFunction(fixtureSourceAsyncFunction),
				true,
				'async function AsyncFunction () {} should be considered a function'
			)
			equal(
				typeChecker.getType(fixtureSourceAsyncFunction),
				'function',
				'async function AsyncFunction () {} should be considered a function type'
			)
		})
	})

	suite('types', function(suite, test) {
		// Prepare
		const typeTestData = [
			[false, 'boolean'],
			[true, 'boolean'],
			['', 'string'],
			[{}, 'object'],
			[fixtureCompiledClasses.A, 'class'],
			[fixtureCompiledClasses.a, 'function'],
			[fixtureCompiledClasses.b, 'function'],
			[function FunctionClass() {}, 'class'],
			[function functionClass() {}, 'function'],
			[function() {}, 'function'],
			[new Date(), 'date'],
			[new Error(), 'error'],
			[[], 'array'],
			[null, 'null'],
			[undefined, 'undefined'],
			[/a/, 'regexp'],
			[1, 'number']
		]

		// Native
		if (fixtureSourceClasses) {
			typeTestData.push(
				[fixtureSourceClasses.A, 'class'],
				[fixtureSourceClasses.a, 'class'],
				[fixtureSourceClasses.b, 'class']
			)
		} else {
			console.log(
				"didn't add native class types as native classes are not supported on this environment"
			)
		}
		if (fixtureMap) {
			typeTestData.push([fixtureMap, 'map'])
		}
		if (fixtureWeakMap) {
			typeTestData.push([fixtureWeakMap, 'weakmap'])
		}

		// Handler
		function testType(value, typeExpected, typeActual) {
			test(`should detect ${inspect(
				value
			)} is of type ${typeExpected}`, function() {
				equal(typeActual, typeExpected)
			})
		}

		// Run
		// Do this for for...of as babel's compilation of that doesn't work with node 0.10
		typeTestData.forEach(function(item) {
			const value = item[0]
			const typeExpected = item[1]
			const typeActual = typeChecker.getType(value)
			testType(value, typeExpected, typeActual)
		})
	})

	suite('custom type map', function(suite, test) {
		const customTypeMap = {
			truthy: value => Boolean(value)
		}
		test('custom match', function() {
			equal(
				typeChecker.getType('hello', customTypeMap),
				'truthy',
				'truthy came back as expected using custom type map'
			)
		})
		test('custom exception', function() {
			equal(
				typeChecker.getType(false, customTypeMap),
				null,
				'null came back as expected as we had no custom type for falsey'
			)
		})
	})
})
