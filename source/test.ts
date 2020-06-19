/* eslint no-console:0, no-undefined:0, no-magic-numbers:0, new-cap:0, no-eval:0 */

// Import
import * as path from 'path'
import { equal, inspect, errorEqual } from 'assert-helpers'
import { suite } from 'kava'
import * as typeChecker from './'

// Environment
const fixtureCompiledClasses = require('../fixtures/classes-compiled.js')
let fixtureSourceClasses: typeof import('../fixtures/classes.js'),
	fixtureSourceAsyncFunction: typeof import('../fixtures/async.js'),
	fixtureMap: typeof import('../fixtures/map.js'),
	fixtureMapEmpty: typeof import('../fixtures/map.js'),
	fixtureWeakMap: typeof import('../fixtures/weakmap.js'),
	fixtureWeakMapEmpty: typeof import('../fixtures/weakmap-empty.js')
try {
	fixtureSourceClasses = require('../fixtures/classes.js')
	console.log('native classes supported on this environment')
} catch (err) {
	console.log('native classes NOT supported on this environment', err.message)
}
try {
	fixtureSourceAsyncFunction = require('../fixtures/async.js')
	console.log('native classes supported on this environment')
} catch (err) {
	console.log('native classes NOT supported on this environment', err.message)
}
try {
	fixtureMap = require('../fixtures/map.js')
	console.log('native Map supported on this environment')
} catch (err) {
	console.log('native Map NOT supported on this environment', err.message)
}
try {
	fixtureMapEmpty = require('../fixtures/map-empty.js')
	console.log('native Map supported on this environment')
} catch (err) {
	console.log('native Map NOT supported on this environment', err.message)
}
try {
	fixtureWeakMap = require('../fixtures/weakmap.js')
	console.log('native WeakMap supported on this environment')
} catch (err) {
	console.log('native WeakMap NOT supported on this environment', err.message)
}
try {
	fixtureWeakMapEmpty = require('../fixtures/weakmap-empty.js')
	console.log('native WeakMap supported on this environment')
} catch (err) {
	console.log('native WeakMap NOT supported on this environment', err.message)
}

// Checks
const checks: Array<[string, any, boolean | string]> = [
	['isNullish', null, true],
	['isNullish', '', false],
	['isNullish', 0, false],
	['isNullish', false, false],
	['isEmptyPlainObject', {}, true],
	['isEmptyPlainObject', { a: 1 }, false],
	['isEmptyPlainObject', false, 'value was not a plain object'],
	['isEmptyArray', [], true],
	['isEmptyArray', [1], false],
	['isEmptyArray', false, 'value was not an array'],
]

// Types
suite('typechecker', function (suite) {
	suite('value', function (suite, test) {
		test('isObject', function () {
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

		test('isPlainObject', function () {
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

		test('isNativeClass', function () {
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
				typeChecker.isNativeClass(function () {}),
				false,
				'function () {} should not be considered native class'
			)
		})

		test('isConventionalClass', function () {
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
				typeChecker.isConventionalClass(function () {}),
				false,
				'function () {} should not be considered conventional class'
			)
			equal(
				typeChecker.isConventionalClass(eval('(function(BasePlugin){})')),
				false,
				'function(BasePlugin){} should not be considered conventional class'
			)
		})

		test('isAsyncFunction', function () {
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

		test('isEmptyMap', function () {
			if (!fixtureWeakMap) {
				console.log('skipping checks as maps not supported on this environment')
				return
			}
			equal(
				typeChecker.isEmptyMap(fixtureMap),
				false,
				'new Map(entries) should not be considered empty'
			)
			equal(
				typeChecker.isEmptyMap(fixtureMapEmpty),
				true,
				'new Map() should not be considered empty'
			)
			try {
				typeChecker.isEmptyMap([])
				throw new Error('isEmptyMap([]) should have failed')
			} catch (err) {
				errorEqual(err, 'value was not a map')
			}
		})

		test('isEmptyWeakMap', function () {
			if (!fixtureWeakMap) {
				console.log(
					'skipping checks as weak maps not supported on this environment'
				)
				return
			}
			equal(
				typeChecker.isEmptyWeakMap(fixtureWeakMap),
				false,
				'new WeakMap(entries) should not be considered empty'
			)
			equal(
				typeChecker.isEmptyWeakMap(fixtureWeakMapEmpty),
				true,
				'new WeakMap() should be considered empty'
			)
			try {
				typeChecker.isEmptyWeakMap([])
				throw new Error('isEmptyWeakMap([]) should have failed')
			} catch (err) {
				errorEqual(err, 'value was not a map')
			}
		})
	})

	suite('checks', function (suite, test) {
		checks.forEach(function ([fn, value, expected]) {
			const call = `${fn}(${JSON.stringify(value)})`
			test(call, function () {
				try {
					// @ts-ignore
					const actual = typeChecker[fn](value)
					equal(actual, expected, `${call} to be ${expected}`)
				} catch (err) {
					if (typeof expected === 'string') {
						errorEqual(err, expected)
					} else throw err
				}
			})
		})
	})

	suite('types', function (suite, test) {
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
			[function () {}, 'function'],
			[new Date(), 'date'],
			[new Error(), 'error'],
			[[], 'array'],
			[null, 'null'],
			[undefined, 'undefined'],
			[/a/, 'regexp'],
			[1, 'number'],
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
		function testType(value: any, typeExpected: any, typeActual: any) {
			test(`should detect ${inspect(
				value
			)} is of type ${typeExpected}`, function () {
				equal(typeActual, typeExpected)
			})
		}

		// Run
		// Do this for for...of as babel's compilation of that doesn't work with node 0.10
		typeTestData.forEach(function (item) {
			const value = item[0]
			const typeExpected = item[1]
			const typeActual = typeChecker.getType(value)
			testType(value, typeExpected, typeActual)
		})
	})

	suite('custom type map', function (suite, test) {
		const customTypeMap: typeChecker.TypeMap = {
			truthy: (value) => Boolean(value),
		}
		test('custom match', function () {
			equal(
				typeChecker.getType('hello', customTypeMap),
				'truthy',
				'truthy came back as expected using custom type map'
			)
		})
		test('custom exception', function () {
			equal(
				typeChecker.getType(false, customTypeMap),
				null,
				'null came back as expected as we had no custom type for falsey'
			)
		})
	})
})
