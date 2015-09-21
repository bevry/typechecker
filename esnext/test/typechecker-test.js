// Import
const {equal, inspect} = require('assert-helpers')
const joe = require('joe')
const typeChecker = require('../..')


// =====================================
// Tests

// Types
joe.describe('typechecker', function (describe) {

	describe('value', function (describe, it) {
		it('isPlainObject', function () {
			class A {}
			equal(typeChecker.isPlainObject({}), true, 'object {} should be a plain object')
			equal(typeChecker.isPlainObject(new A()), false, 'class A instantiation should not be a plain object')
		})

		it('isEmpty', function () {
			equal(typeChecker.isEmpty(null), true, 'null should be considered empty')
			equal(typeChecker.isEmpty(), true, 'undefined should be considered empty')
			equal(typeChecker.isEmpty(false), false, 'false should not be considered empty')
			equal(typeChecker.isEmpty(0), false, '0 should not be considered empty')
			equal(typeChecker.isEmpty(''), false, '"" should not be considered empty')
			equal(typeChecker.isEmpty({}), false, '{} should not be considered empty')
		})

		it('isEmptyObject', function () {
			class A {}
			class B {
				z () {}
			}
			class C extends B {}
			class D extends C {
				constructor () {
					super()
					this.greeting = 'hello'
				}
			}
			equal(typeChecker.isEmptyObject({}), true, '{} should be considered empty')
			equal(typeChecker.isEmptyObject(new Map()), true, 'new Map() should be considered empty')
			equal(typeChecker.isEmptyObject(new WeakMap()), true, 'new WeakMap() should be considered empty')
			equal(typeChecker.isEmptyObject({a: 1}), false, '{a: 1} should not be considered empty')
			equal(typeChecker.isEmptyObject(new A()), true, 'class A instantiation should be considered empty')
			equal(typeChecker.isEmptyObject(new B()), true, 'class B instantiation should not be considered empty')
			equal(typeChecker.isEmptyObject(new C()), true, 'class C instantiation should be considered empty')
			equal(typeChecker.isEmptyObject(new D()), false, 'class D instantiation should not be considered empty')
		})

		it('isNativeClass', function () {
			let A, B
			try {
				/* eslint no-eval:0 */
				eval('A = class A {}')
				eval('B = class {}')
			}
			catch ( err ) {
				console.log('Test skipped as native classes are not supported on this environment: ' + err.message)
				return
			}
			equal(typeChecker.isNativeClass(A), true, 'class A {} should be considered native class')
			equal(typeChecker.isNativeClass(B), true, 'class {} should be considered native class')
			equal(typeChecker.isNativeClass(function () {}), false, 'function () {} should not be considered native class')
		})

		it('isConventionalClass', function () {
			equal(typeChecker.isConventionalClass(class A {}), true, 'compiled class A {} should be considered conventional class')
			equal(typeChecker.isConventionalClass(class a {}), false, 'compiled class {} should not be considered conventional class')
			equal(typeChecker.isConventionalClass(class {}), false, 'compiled class {} should not be considered conventional class')
			equal(typeChecker.isConventionalClass(function B () {}), true, 'function B () {} should be considered conventional class')
			equal(typeChecker.isConventionalClass(function b () {}), false, 'function b () {} should not be considered conventional class')
			equal(typeChecker.isConventionalClass(function () {}), false, 'function () {} should not be considered conventional class')
		})
	})

	describe('types', function (describe, it) {
		// Prepare
		const typeTestData = [
			[false, 'boolean'],
			[true, 'boolean'],
			['', 'string'],
			[{}, 'object'],
			[new Map(), 'map'],
			[new WeakMap(), 'weakmap'],
			[class CompiledNativeClass {}, 'class'],
			[class compiledNativeClass {}, 'function'],
			[class {}, 'function'],
			[function FunctionClass () {}, 'class'],
			[function functionClass () {}, 'function'],
			[function () {}, 'function'],
			[new Date(), 'date'],
			[new Error(), 'error'],
			[[], 'array'],
			[null, 'null'],
			/* eslint no-undefined:0 */
			[undefined, 'undefined'],
			[/a/, 'regexp'],
			[1, 'number'],
		]

		try {
			eval("typeTestData.push([class NativeClass {}, 'class'], [class nativeClass {}, 'class'], [class {}, 'class'])")
		}
		catch ( err ) {
			console.log("Didn't add native class types as native classes are not supported on this environment: " + err.message)
		}

		// Handler
		function testType (value, typeExpected, typeActual) {
			it(`should detect ${inspect(value)} is of type ${typeExpected}`, function () {
				equal(typeActual, typeExpected)
			})
		}

		// Run
		for ( let [value, typeExpected] of typeTestData ) {
			const typeActual = typeChecker.getType(value)
			testType(value, typeExpected, typeActual)
		}
	})
})
