/* eslint no-console:0, no-undefined:0, no-magic-numbers:0, new-cap:0, no-eval:0 */

// Import
import { equal, inspect, errorEqual } from 'assert-helpers'
import kava from 'kava'
import * as typeChecker from './index.js'
import fixtures from '../test-fixtures/index.js'

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
kava.suite('typechecker', function (suite) {
	suite('value', function (suite, test) {
		test('isObject', function () {
			equal(typeChecker.isObject({}), true, 'object {} should be a object')
			equal(typeChecker.isObject(null), false, 'null should not be a object')
			equal(typeChecker.isObject('a'), false, 'string should not be a object')
			equal(
				typeChecker.isObject(''),
				false,
				'empty string should not be a object',
			)
			equal(typeChecker.isObject(), false, 'undefined should not be a object')
		})

		test('isPlainObject', function () {
			equal(
				typeChecker.isPlainObject({}),
				true,
				'object {} should be a plain object',
			)
			equal(
				typeChecker.isPlainObject(null),
				false,
				'null should not be a plain object',
			)
			equal(
				typeChecker.isPlainObject('a'),
				false,
				'string should not be a plain object',
			)
			equal(
				typeChecker.isPlainObject(''),
				false,
				'empty string should not be a plain object',
			)
			equal(
				typeChecker.isPlainObject(),
				false,
				'undefined should not be a plain object',
			)
			if (fixtures.fixtureSourceClasses) {
				equal(
					typeChecker.isPlainObject(new fixtures.fixtureSourceClasses.A()),
					false,
					'native clas instantiation should not be a plain object',
				)
			}
			equal(
				// @ts-ignore
				typeChecker.isPlainObject(new fixtures.fixtureCompiledClasses.A()),
				false,
				'conventional class instantiation should not be a plain object',
			)
		})

		test('isNativeClass', function () {
			if (!fixtures.fixtureSourceClasses) {
				console.log(
					'skipping checks as native classes not supported on this environment',
				)
				return
			}
			equal(
				typeChecker.isNativeClass(fixtures.fixtureSourceClasses.A),
				true,
				'class A {} should be considered native class',
			)
			equal(
				typeChecker.isNativeClass(fixtures.fixtureSourceClasses.b),
				true,
				'class {} should be considered native class',
			)
			equal(
				typeChecker.isNativeClass(fixtures.fixtureSourceClasses.C),
				true,
				'class C extends A {} should be considered native class',
			)
			equal(
				typeChecker.isNativeClass(function () {}),
				false,
				'function () {} should not be considered native class',
			)
		})

		test('isConventionalClass', function () {
			equal(
				typeChecker.isConventionalClass(fixtures.fixtureCompiledClasses.A),
				true,
				'compiled class A {} should be considered conventional class',
			)
			equal(
				typeChecker.isConventionalClass(fixtures.fixtureCompiledClasses.a),
				false,
				'compiled class a {} should not be considered conventional class',
			)
			equal(
				typeChecker.isConventionalClass(fixtures.fixtureCompiledClasses.b),
				false,
				'compiled class {} should not be considered conventional class',
			)
			equal(
				typeChecker.isConventionalClass(fixtures.fixtureCompiledClasses.C),
				true,
				'compiled class C extends A {} should not be considered conventional class',
			)
			equal(
				typeChecker.isConventionalClass(function B() {}),
				true,
				'function B () {} should be considered conventional class',
			)
			equal(
				typeChecker.isConventionalClass(function b() {}),
				false,
				'function b () {} should not be considered conventional class',
			)
			equal(
				typeChecker.isConventionalClass(function () {}),
				false,
				'function () {} should not be considered conventional class',
			)
			equal(
				typeChecker.isConventionalClass(eval('(function(BasePlugin){})')),
				false,
				'function(BasePlugin){} should not be considered conventional class',
			)
		})

		test('isAsyncFunction', function () {
			if (!fixtures.fixtureSourceAsyncFunction) {
				console.log(
					'skipping checks as native async functions not supported on this environment',
				)
				return
			}
			equal(
				typeChecker.isAsyncFunction(fixtures.fixtureSourceAsyncFunction),
				true,
				'async function AsyncFunction () {} should be considered an async function',
			)
			equal(
				typeChecker.isSyncFunction(fixtures.fixtureSourceAsyncFunction),
				false,
				'async function AsyncFunction () {} should not be considered a sync function',
			)
			equal(
				typeChecker.isFunction(fixtures.fixtureSourceAsyncFunction),
				true,
				'async function AsyncFunction () {} should be considered a function',
			)
			equal(
				typeChecker.getType(fixtures.fixtureSourceAsyncFunction),
				'function',
				'async function AsyncFunction () {} should be considered a function type',
			)
		})

		test('isEmptyMap', function () {
			if (!fixtures.fixtureWeakMap) {
				console.log('skipping checks as maps not supported on this environment')
				return
			}
			equal(
				typeChecker.isEmptyMap(fixtures.fixtureMap),
				false,
				'new Map(entries) should not be considered empty',
			)
			equal(
				typeChecker.isEmptyMap(fixtures.fixtureMapEmpty),
				true,
				'new Map() should not be considered empty',
			)
			try {
				typeChecker.isEmptyMap([])
				throw new Error('isEmptyMap([]) should have failed')
			} catch (err) {
				errorEqual(err, 'value was not a map')
			}
		})

		test('isEmptyWeakMap', function () {
			if (!fixtures.fixtureWeakMap) {
				console.log(
					'skipping checks as weak maps not supported on this environment',
				)
				return
			}
			equal(
				typeChecker.isEmptyWeakMap(fixtures.fixtureWeakMap),
				false,
				'new WeakMap(entries) should not be considered empty',
			)
			equal(
				typeChecker.isEmptyWeakMap(fixtures.fixtureWeakMapEmpty),
				true,
				'new WeakMap() should be considered empty',
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
			[fixtures.fixtureCompiledClasses.A, 'class'],
			[fixtures.fixtureCompiledClasses.a, 'function'],
			[fixtures.fixtureCompiledClasses.b, 'function'],
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
		if (fixtures.fixtureSourceClasses) {
			typeTestData.push(
				[fixtures.fixtureSourceClasses.A, 'class'],
				[fixtures.fixtureSourceClasses.a, 'class'],
				[fixtures.fixtureSourceClasses.b, 'class'],
			)
		} else {
			console.log(
				"didn't add native class types as native classes are not supported on this environment",
			)
		}
		if (fixtures.fixtureMap) {
			typeTestData.push([fixtures.fixtureMap, 'map'])
		}
		if (fixtures.fixtureWeakMap) {
			typeTestData.push([fixtures.fixtureWeakMap, 'weakmap'])
		}

		// Handler
		function testType(value: any, typeExpected: any, typeActual: any) {
			test(`should detect ${inspect(
				value,
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
				'truthy came back as expected using custom type map',
			)
		})
		test('custom exception', function () {
			equal(
				typeChecker.getType(false, customTypeMap),
				null,
				'null came back as expected as we had no custom type for falsey',
			)
		})
	})
})
