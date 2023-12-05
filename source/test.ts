/* eslint no-console:0, no-undefined:0, no-magic-numbers:0, new-cap:0, no-eval:0 */

// Import
import { equal, inspect, errorEqual } from 'assert-helpers'
import kava from 'kava'
import fixtures from '../test-fixtures/index.js'

import {
	getObjectType,
	isObject,
	isPlainObject,
	isNativeClass,
	isConventionalClass,
	isClass,
	isError,
	isDate,
	isArguments,
	isSyncFunction,
	isAsyncFunction,
	isFunction,
	isRegExp,
	isArray,
	isNumber,
	isString,
	isBoolean,
	isNull,
	isUndefined,
	isMap,
	isWeakMap,
	isNullish,
	isEmptyArray,
	isEmptyPlainObject,
	isEmptyMap,
	isEmptyWeakMap,
	typeMap,
	getType,
	TypeMap,
	AnyArray,
	AnyNumber,
	AnyString,
	AnyBoolean,
	AnyMap,
	AnyWeakMap,
	Nullish,
	PlainObject,
	isEmptyKeys,
} from './index.js'
import * as typeChecker from './index.js'

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
			equal(isObject({}), true, 'object {} should be a object')
			equal(isObject(null), false, 'null should not be a object')
			equal(isObject('a'), false, 'string should not be a object')
			equal(isObject(''), false, 'empty string should not be a object')
			equal(isObject(), false, 'undefined should not be a object')
		})

		test('isPlainObject', function () {
			equal(isPlainObject({}), true, 'object {} should be a plain object')
			equal(isPlainObject(null), false, 'null should not be a plain object')
			equal(isPlainObject('a'), false, 'string should not be a plain object')
			equal(
				isPlainObject(''),
				false,
				'empty string should not be a plain object'
			)
			equal(isPlainObject(), false, 'undefined should not be a plain object')
			if (fixtures.fixtureSourceClasses) {
				equal(
					isPlainObject(new fixtures.fixtureSourceClasses.A()),
					false,
					'native class instantiation should not be a plain object'
				)
			}
			equal(
				// @ts-ignore
				isPlainObject(new fixtures.fixtureCompiledClasses.A()),
				false,
				'conventional class instantiation should not be a plain object'
			)
		})

		test('isNativeClass', function () {
			if (!fixtures.fixtureSourceClasses) {
				console.log(
					'skipping checks as native classes not supported on this environment'
				)
				return
			}
			equal(
				isNativeClass(fixtures.fixtureSourceClasses.A),
				true,
				'class A {} should be considered native class'
			)
			equal(
				isNativeClass(fixtures.fixtureSourceClasses.b),
				true,
				'class {} should be considered native class'
			)
			equal(
				isNativeClass(fixtures.fixtureSourceClasses.C),
				true,
				'class C extends A {} should be considered native class'
			)
			equal(
				isNativeClass(function () {}),
				false,
				'function () {} should not be considered native class'
			)
		})

		test('isConventionalClass', function () {
			equal(
				isConventionalClass(fixtures.fixtureCompiledClasses.A),
				true,
				'compiled class A {} should be considered conventional class'
			)
			equal(
				isConventionalClass(fixtures.fixtureCompiledClasses.a),
				false,
				'compiled class a {} should not be considered conventional class'
			)
			equal(
				isConventionalClass(fixtures.fixtureCompiledClasses.b),
				false,
				'compiled class {} should not be considered conventional class'
			)
			equal(
				isConventionalClass(fixtures.fixtureCompiledClasses.C),
				true,
				'compiled class C extends A {} should not be considered conventional class'
			)
			equal(
				isConventionalClass(function B() {}),
				true,
				'function B () {} should be considered conventional class'
			)
			equal(
				isConventionalClass(function b() {}),
				false,
				'function b () {} should not be considered conventional class'
			)
			equal(
				isConventionalClass(function () {}),
				false,
				'function () {} should not be considered conventional class'
			)
			equal(
				isConventionalClass(eval('(function(BasePlugin){})')),
				false,
				'function(BasePlugin){} should not be considered conventional class'
			)
		})

		test('isAsyncFunction', function () {
			if (!fixtures.fixtureSourceAsyncFunction) {
				console.log(
					'skipping checks as native async functions not supported on this environment'
				)
				return
			}
			equal(
				isAsyncFunction(fixtures.fixtureSourceAsyncFunction),
				true,
				'async function AsyncFunction () {} should be considered an async function'
			)
			equal(
				isSyncFunction(fixtures.fixtureSourceAsyncFunction),
				false,
				'async function AsyncFunction () {} should not be considered a sync function'
			)
			equal(
				isFunction(fixtures.fixtureSourceAsyncFunction),
				true,
				'async function AsyncFunction () {} should be considered a function'
			)
			equal(
				getType(fixtures.fixtureSourceAsyncFunction),
				'function',
				'async function AsyncFunction () {} should be considered a function type'
			)
		})

		test('isEmptyMap', function () {
			if (!fixtures.fixtureWeakMap) {
				console.log('skipping checks as maps not supported on this environment')
				return
			}
			equal(
				isEmptyMap(fixtures.fixtureMap),
				false,
				'new Map(entries) should not be considered empty'
			)
			equal(
				isEmptyMap(fixtures.fixtureMapEmpty),
				true,
				'new Map() should not be considered empty'
			)
			try {
				isEmptyMap([])
				throw new Error('isEmptyMap([]) should have failed')
			} catch (err) {
				errorEqual(err, 'value was not a map')
			}
		})

		test('isEmptyWeakMap', function () {
			if (!fixtures.fixtureWeakMap) {
				console.log(
					'skipping checks as weak maps not supported on this environment'
				)
				return
			}
			equal(
				isEmptyWeakMap(fixtures.fixtureWeakMap),
				false,
				'new WeakMap(entries) should not be considered empty'
			)
			equal(
				isEmptyWeakMap(fixtures.fixtureWeakMapEmpty),
				true,
				'new WeakMap() should be considered empty'
			)
			try {
				isEmptyWeakMap([])
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
				[fixtures.fixtureSourceClasses.b, 'class']
			)
		} else {
			console.log(
				"didn't add native class types as native classes are not supported on this environment"
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
			const typeActual = getType(value)
			testType(value, typeExpected, typeActual)
		})
	})

	suite('custom type map', function (suite, test) {
		const customTypeMap: TypeMap = {
			truthy: (value) => Boolean(value),
		}
		test('custom match', function () {
			equal(
				getType('hello', customTypeMap),
				'truthy',
				'truthy came back as expected using custom type map'
			)
		})
		test('custom exception', function () {
			equal(
				getType(false, customTypeMap),
				null,
				'null came back as expected as we had no custom type for falsey'
			)
		})
	})

	/* eslint prefer-rest-params:0, no-array-constructor:0, no-new-wrappers:0 */
	suite('typechecking', function (suite, test) {
		test('isObject', function () {
			const t1: true = isObject({})
			const t2: true = isObject({ a: 1 })
			const t3: true = isObject(new Date())
			const f1: false = isObject(null)
			const v: unknown = 'this value does not matter'
			if (isObject(v)) {
				const o: object = v
			} else {
				// @ts-expect-error
				const n: object = v
			}
		})
		test('isPlainObject', function () {
			const t1: true = isPlainObject({})
			const t2: true = isPlainObject({ a: 1 })
			const f1: false = isPlainObject(new Date())
			const f2: false = isPlainObject(null)
			const v: unknown = 'this value does not matter'
			if (isPlainObject(v)) {
				const o: object = v
			} else {
				// @ts-expect-error
				const n: object = v
			}
		})
		test('isNativeClass', function () {
			const t1: true = isNativeClass(class A {})
			const f1: false = isNativeClass({})
			const f2: false = isNativeClass(new Date())
			const f3: false = isNativeClass(function () {})
			const v: unknown = 'this value does not matter'
			if (isNativeClass(v)) {
				const o: object = v
			} else {
				// @ts-expect-error
				const n: object = v
			}
		})
		test('isConventionalClass', function () {
			const f1: false = isConventionalClass(class A {})
			const f2: false = isConventionalClass({})
			const f3: false = isConventionalClass(new Date())
			const b1: boolean = isConventionalClass(function () {})
			const b2: boolean = isConventionalClass(function A() {})
			const v: unknown = 'this value does not matter'
			if (isConventionalClass(v)) {
				const g: Function = v
			} else {
				// @ts-expect-error
				const n: Function = v
			}
		})
		test('isClass', function () {
			const t1: true = isClass(class A {})
			const f1: false = isClass({})
			const f2: false = isClass(new Date())
			const b1: boolean = isClass(function () {})
			const b2: boolean = isClass(function A() {})
			const v: unknown = 'this value does not matter'
			if (isClass(v)) {
				const g: Function = v
			} else {
				// @ts-expect-error
				const n: Function = v
			}
		})
		test('isError', function () {
			const f1: false = isError(class A {})
			const f2: false = isError({})
			const t1: true = isError(new Error())
			const t2: true = isError(new (class A extends Error {})())
			const v: unknown = 'this value does not matter'
			if (isError(v)) {
				const g: Error = v
			} else {
				// @ts-expect-error
				const n: Error = v
			}
		})
		test('isDate', function () {
			const f1: false = isDate(class A {})
			const f2: false = isDate({})
			const t1: true = isDate(new Date())
			const t2: true = isDate(new (class A extends Date {})())
			const v: unknown = 'this value does not matter'
			if (isDate(v)) {
				const g: Date = v
			} else {
				// @ts-expect-error
				const n: Date = v
			}
		})
		test('isArguments', function () {
			const f1: false = isArguments([])
			const f2: false = isArguments(new Set())
			const t1: true = isArguments(arguments)
			const v: unknown = 'this value does not matter'
			if (isArguments(v)) {
				const g: IArguments = v
			} else {
				// @ts-expect-error
				const n: IArguments = v
			}
		})
		test('isSyncFunction', function () {
			const f1: false = isSyncFunction([])
			const f2: false = isSyncFunction(new Set())
			const f3: false = isSyncFunction({})
			const b1: boolean = isSyncFunction(function () {})
			if (fixtures.fixtureSourceAsyncFunction) {
				const b2: boolean = isSyncFunction(fixtures.fixtureSourceAsyncFunction)
			}
			const v: unknown = 'this value does not matter'
			if (isSyncFunction(v)) {
				const g: Function = v
			} else {
				// @ts-expect-error
				const n: Function = v
			}
		})
		test('isAsyncFunction', function () {
			const f1: false = isAsyncFunction([])
			const f2: false = isAsyncFunction(new Set())
			const f3: false = isAsyncFunction({})
			const b1: boolean = isAsyncFunction(function () {})
			if (fixtures.fixtureSourceAsyncFunction) {
				const b2: boolean = isAsyncFunction(fixtures.fixtureSourceAsyncFunction)
			}
			const v: unknown = 'this value does not matter'
			if (isAsyncFunction(v)) {
				const g: Function = v
			} else {
				// @ts-expect-error
				const n: Function = v
			}
		})
		test('isFunction', function () {
			const f1: false = isFunction([])
			const f2: false = isFunction(new Set())
			const f3: false = isFunction({})
			const t1: true = isFunction(function () {})
			if (fixtures.fixtureSourceAsyncFunction) {
				const t2: true = isFunction(fixtures.fixtureSourceAsyncFunction)
			}
			const v: unknown = 'this value does not matter'
			if (isFunction(v)) {
				const g: Function = v
			} else {
				// @ts-expect-error
				const n: Function = v
			}
		})
		test('isRegExp', function () {
			const f1: false = isRegExp([])
			const f2: false = isRegExp(new Set())
			const f3: false = isRegExp({})
			const f4: false = isRegExp(function () {})
			const t1: true = isRegExp(new RegExp('a'))
			const t2: true = isRegExp(/a/)
			const v: unknown = 'this value does not matter'
			if (isRegExp(v)) {
				const g: RegExp = v
			} else {
				// @ts-expect-error
				const n: RegExp = v
			}
		})
		test('isArray', function () {
			const f1: false = isArray(new Set())
			const f2: false = isArray({})
			const t1: true = isArray([])
			const t2: true = isArray([1])
			const t3: true = isArray(new Array())
			const v: unknown = 'this value does not matter'
			if (isArray(v)) {
				const g: AnyArray = v
			} else {
				// @ts-expect-error
				const n: AnyArray = v
			}
		})
		test('isNumber', function () {
			const f1: false = isNumber('0')
			const f2: false = isNumber({})
			const t1: true = isNumber(0)
			const t2: true = isNumber(new Number(0))
			const v: unknown = 'this value does not matter'
			if (isNumber(v)) {
				const g: AnyNumber = v
			} else {
				// @ts-expect-error
				const n: AnyNumber = v
			}
		})
		test('isString', function () {
			const f1: false = isString(1)
			const f2: false = isString({})
			const t1: true = isString('')
			const t2: true = isString(new String(''))
			const v: unknown = 'this value does not matter'
			if (isString(v)) {
				const g: AnyString = v
			} else {
				// @ts-expect-error
				const n: AnyString = v
			}
		})
		test('isBoolean', function () {
			const f1: false = isBoolean(1)
			const f2: false = isBoolean('true')
			const t1: true = isBoolean(true)
			const t2: true = isBoolean(false)
			const t3: true = isBoolean(new Boolean(true))
			const t4: true = isBoolean(new Boolean(false))
			const v: unknown = 'this value does not matter'
			if (isBoolean(v)) {
				const g: AnyBoolean = v
			} else {
				// @ts-expect-error
				const n: AnyBoolean = v
			}
		})
		test('isNull', function () {
			const f1: false = isNull(0)
			const f2: false = isNull('')
			const f3: false = isNull()
			const f4: false = isNull(undefined)
			const t1: true = isNull(null)
			const v: unknown = 'this value does not matter'
			if (isNull(v)) {
				const g: null = v
			} else {
				// @ts-expect-error
				const n: null = v
			}
		})
		test('isUndefined', function () {
			const f1: false = isUndefined(0)
			const f2: false = isUndefined('')
			const f3: false = isUndefined(null)
			const t1: true = isUndefined(undefined)
			const t2: true = isUndefined()
			const v: unknown = 'this value does not matter'
			if (isUndefined(v)) {
				const g: undefined = v
			} else {
				// @ts-expect-error
				const n: undefined = v
			}
		})
		test('isMap', function () {
			const f1: false = isMap({})
			const f2: false = isMap({ a: 1 })
			const f3: false = isMap(null)
			const f4: false = isMap('')
			const f5: false = isMap(new WeakMap())
			const t1: true = isMap(new Map())
			const t2: true = isMap(new Map<number, number>([[1, 2]]))
			const v: unknown = 'this value does not matter'
			if (isMap(v)) {
				const g: AnyMap = v
			} else {
				// @ts-expect-error
				const n: AnyMap = v
			}
		})
		test('isWeakMap', function () {
			const f1: false = isWeakMap({})
			const f2: false = isWeakMap({ a: 1 })
			const f3: false = isWeakMap(null)
			const f4: false = isWeakMap('')
			const f5: false = isWeakMap(new Map())
			const t1: true = isWeakMap(new WeakMap())
			const v: unknown = 'this value does not matter'
			if (isWeakMap(v)) {
				const g: AnyWeakMap = v
			} else {
				// @ts-expect-error
				const n: AnyWeakMap = v
			}
		})
		test('isNullish', function () {
			const f1: false = isNullish(0)
			const f2: false = isNullish('')
			const t1: true = isNullish(undefined)
			const t2: true = isNullish()
			const t3: true = isNullish(null)
			const v: unknown = 'this value does not matter'
			if (isNullish(v)) {
				const g: Nullish = v
			} else {
				// @ts-expect-error
				const n: Nullish = v
			}
		})
		test('isEmptyArray', function () {
			// do not throw hack
			if (Math.random() > 1) {
				const n1: never = isEmptyArray(0)
				const n2: never = isEmptyArray('')
				const n3: never = isEmptyArray(undefined)
				const n4: never = isEmptyArray()
				const n5: never = isEmptyArray(null)
				const n6: never = isEmptyArray(new Map())
				const n7: never = isEmptyArray(new (class A {})())
				const n8: never = isEmptyArray({ a: 1 })
				const n9: never = isEmptyArray({})
				const f1: false = isEmptyArray([1])
				const t1: true = isEmptyArray([])
			}
			const v: unknown = [] // do not throw
			if (isEmptyArray(v)) {
				const g: AnyArray = v
			} else {
				// @ts-expect-error
				const n: AnyArray = v
			}
		})
		test('isEmptyPlainObject', function () {
			// do not throw hack
			if (Math.random() > 1) {
				const n1: never = isEmptyPlainObject(0)
				const n2: never = isEmptyPlainObject('')
				const n3: never = isEmptyPlainObject(undefined)
				const n4: never = isEmptyPlainObject()
				const n5: never = isEmptyPlainObject(null)
				const n6: never = isEmptyPlainObject(new Map())
				const n7: never = isEmptyPlainObject(new (class A {})())
				const b1: boolean = isEmptyPlainObject({ a: 1 })
				const b2: boolean = isEmptyPlainObject({})
			}
			const v: unknown = {} // do not throw
			if (isEmptyPlainObject(v)) {
				const g: PlainObject = v
			} else {
				// @ts-expect-error
				const n: PlainObject = v
			}
		})
		test('isEmptyMap', function () {
			// do not throw hack
			if (Math.random() > 1) {
				const n1: never = isEmptyMap(0)
				const n2: never = isEmptyMap('')
				const n3: never = isEmptyMap(undefined)
				const n4: never = isEmptyMap()
				const n5: never = isEmptyMap(null)
				const n6: never = isEmptyMap({})
				const n7: never = isEmptyMap(new (class A {})())
				const n8: never = isEmptyMap({ a: 1 })
				const n9: never = isEmptyMap(new WeakMap())
				const b1: boolean = isEmptyMap(new Map())
				const b2: boolean = isEmptyMap(new Map<number, number>([[1, 2]]))
			}
			const v: unknown = new Map() // do not throw
			if (isEmptyMap(v)) {
				const g: AnyMap = v
			} else {
				// @ts-expect-error
				const n: AnyMap = v
			}
		})
		test('isEmptyWeakMap', function () {
			// do not throw hack
			if (Math.random() > 1) {
				const n1: never = isEmptyWeakMap(0)
				const n2: never = isEmptyWeakMap('')
				const n3: never = isEmptyWeakMap(undefined)
				const n4: never = isEmptyWeakMap()
				const n5: never = isEmptyWeakMap(null)
				const n6: never = isEmptyWeakMap({})
				const n7: never = isEmptyWeakMap(new (class A {})())
				const n8: never = isEmptyWeakMap({ a: 1 })
				const n9: never = isEmptyWeakMap(new Map())
				const b1: boolean = isEmptyWeakMap(new WeakMap())
			}
			const v: unknown = new WeakMap() // do not throw
			if (isEmptyWeakMap(v)) {
				const g: AnyWeakMap = v
			} else {
				// @ts-expect-error
				const n: AnyWeakMap = v
			}
		})
		test('isEmptyKeys', function () {
			const f1: false = isEmptyKeys(0)
			const f2: false = isEmptyKeys('')
			const f3: false = isEmptyKeys(undefined)
			const f4: false = isEmptyKeys()
			const f5: false = isEmptyKeys(null)
			const f6: false = isEmptyKeys([1])
			const t1: true = isEmptyKeys([])
			const b1: boolean = isEmptyKeys({})
			const b2: boolean = isEmptyKeys(new WeakMap())
			const b3: boolean = isEmptyKeys(new Map())
			const b4: boolean = isEmptyKeys(new (class A {})())
			const b5: boolean = isEmptyKeys({ a: 1 })
			const v: unknown = 'this value does not matter'
			// no types predicate
		})
	})
})
