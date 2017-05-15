/* eslint no-console:0, space-before-keywords:0, no-undefined:0, no-magic-numbers:0, new-cap:0, no-eval:0 */
'use strict'

// Import
const { equal, inspect } = require('assert-helpers')
const { suite } = require('joe')
const conventionalFixtures = eval("require('../es2015/test-fixtures.js')")  // eval to work around flow-type
const typeChecker = require('./index.js')

// Environment
try {
	/* eslint no-var:0 */
	var nativeFixtures = require('../source/test-fixtures.js')
	console.log('native classes supported on this environment')
}
catch (err) {
	console.log('native classes NOT supported on this environment', err.message)
}

// Types
suite('typechecker', function (suite, test) {

	suite('value', function (suite, test) {
		test('isObject', function () {
			equal(typeChecker.isObject({}), true, 'object {} should be a object')
			equal(typeChecker.isObject(null), false, 'null should not be a object')
			equal(typeChecker.isObject('a'), false, 'string should not be a object')
			equal(typeChecker.isObject(''), false, 'empty string should not be a object')
			equal(typeChecker.isObject(), false, 'undefined should not be a object')
		})

		test('isPlainObject', function () {
			equal(typeChecker.isPlainObject({}), true, 'object {} should be a plain object')
			equal(typeChecker.isPlainObject(null), false, 'null should not be a plain object')
			equal(typeChecker.isPlainObject('a'), false, 'string should not be a plain object')
			equal(typeChecker.isPlainObject(''), false, 'empty string should not be a plain object')
			equal(typeChecker.isPlainObject(), false, 'undefined should not be a plain object')
			if (nativeFixtures) {
				equal(typeChecker.isPlainObject(new nativeFixtures.A()), false, 'native class instantiation should not be a plain object')
			}
			equal(typeChecker.isPlainObject(new conventionalFixtures.A()), false, 'conventional class instantiation should not be a plain object')
		})

		test('isEmpty', function () {
			equal(typeChecker.isEmpty(null), true, 'null should be considered empty')
			equal(typeChecker.isEmpty(), true, 'undefined should be considered empty')
			equal(typeChecker.isEmpty(false), false, 'false should not be considered empty')
			equal(typeChecker.isEmpty(0), false, '0 should not be considered empty')
			equal(typeChecker.isEmpty(''), false, '"" should not be considered empty')
			equal(typeChecker.isEmpty({}), false, '{} should not be considered empty')
		})

		suite('isEmptyObject', function (suite, test) {
			test('primatives', function () {
				equal(typeChecker.isEmptyObject({}), true, '{} should be considered empty')
				equal(typeChecker.isEmptyObject(new Map()), true, 'new Map() should be considered empty')
				equal(typeChecker.isEmptyObject(new WeakMap()), true, 'new WeakMap() should be considered empty')
				equal(typeChecker.isEmptyObject({ a: 1 }), false, '{a: 1} should not be considered empty')
			})
			test('native classes', function () {
				if (!nativeFixtures) {
					console.log('skipping checks as native classes not supported on this environment')
					return
				}
				equal(typeChecker.isEmptyObject(new nativeFixtures.A()), true, 'class A instantiation should be considered empty')
				equal(typeChecker.isEmptyObject(new nativeFixtures.D()), true, 'class D instantiation should not be considered empty')
				equal(typeChecker.isEmptyObject(new nativeFixtures.E()), true, 'class E instantiation should be considered empty')
				equal(typeChecker.isEmptyObject(new nativeFixtures.F()), false, 'class F instantiation should not be considered empty')
			})
			test('conventional classes', function () {
				equal(typeChecker.isEmptyObject(new conventionalFixtures.A()), true, 'class A instantiation should be considered empty')
				equal(typeChecker.isEmptyObject(new conventionalFixtures.D()), true, 'class D instantiation should not be considered empty')
				equal(typeChecker.isEmptyObject(new conventionalFixtures.E()), true, 'class E instantiation should be considered empty')
				equal(typeChecker.isEmptyObject(new conventionalFixtures.F()), false, 'class F instantiation should not be considered empty')
			})
		})

		test('isNativeClass', function () {
			if (!nativeFixtures) {
				console.log('skipping checks as native classes not supported on this environment')
				return
			}
			equal(typeChecker.isNativeClass(nativeFixtures.A), true, 'class A {} should be considered native class')
			equal(typeChecker.isNativeClass(nativeFixtures.b), true, 'class {} should be considered native class')
			equal(typeChecker.isNativeClass(nativeFixtures.C), true, 'class C extends A {} should be considered native class')
			equal(typeChecker.isNativeClass(function () { }), false, 'function () {} should not be considered native class')
		})

		test('isConventionalClass', function () {
			equal(typeChecker.isConventionalClass(conventionalFixtures.A), true, 'compiled class A {} should be considered conventional class')
			equal(typeChecker.isConventionalClass(conventionalFixtures.a), false, 'compiled class a {} should not be considered conventional class')
			equal(typeChecker.isConventionalClass(conventionalFixtures.b), false, 'compiled class {} should not be considered conventional class')
			equal(typeChecker.isConventionalClass(conventionalFixtures.C), true, 'compiled class C extends A {} should not be considered conventional class')
			equal(typeChecker.isConventionalClass(function B () { }), true, 'function B () {} should be considered conventional class')
			equal(typeChecker.isConventionalClass(function b () { }), false, 'function b () {} should not be considered conventional class')
			equal(typeChecker.isConventionalClass(function () { }), false, 'function () {} should not be considered conventional class')
		})
	})

	suite('types', function (suite, test) {
		// Prepare
		const typeTestData = [
			[false, 'boolean'],
			[true, 'boolean'],
			['', 'string'],
			[{}, 'object'],
			[new Map(), 'map'],
			[new WeakMap(), 'weakmap'],
			[conventionalFixtures.A, 'class'],
			[conventionalFixtures.a, 'function'],
			[conventionalFixtures.b, 'function'],
			[function FunctionClass () { }, 'class'],
			[function functionClass () { }, 'function'],
			[function () { }, 'function'],
			[new Date(), 'date'],
			[new Error(), 'error'],
			[[], 'array'],
			[null, 'null'],
			[undefined, 'undefined'],
			[/a/, 'regexp'],
			[1, 'number']
		]

		// Native
		if (nativeFixtures) {
			typeTestData.push([nativeFixtures.A, 'class'], [nativeFixtures.a, 'class'], [nativeFixtures.b, 'class'])
		}
		else {
			console.log("didn't add native class types as native classes are not supported on this environment")
		}

		// Handler
		function testType (value, typeExpected, typeActual) {
			test(`should detect ${inspect(value)} is of type ${typeExpected}`, function () {
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

	test('custom type map', function () {
		const customTypeMap = {
			map: typeChecker.isMap,
			object: typeChecker.isObject
		}
		equal(
			typeChecker.getType(new Map()),
			'map',
			'weak map came back as expected using default type map'
		)
		equal(
			typeChecker.getType(new WeakMap()),
			'weakmap',
			'weak map came back as xpected using default type map'
		)
		equal(
			typeChecker.getType(new Map(), customTypeMap),
			'map',
			'map came back as expected with custom type map'
		)
		equal(
			typeChecker.getType(new WeakMap(), customTypeMap),
			'object',
			'weak map came back as object as expected as custom type map discards it'
		)
	})

})
