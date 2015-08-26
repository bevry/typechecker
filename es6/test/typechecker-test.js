// Import
const assert = require('assert')
const joe = require('joe')
const typeChecker = require('../lib/typechecker')
const util = require('util')


// =====================================
// Tests

// Types
joe.describe('typechecker', function (describe) {
	describe('types', function (describe, it) {
		// Prepare
		const typeTestData = [
			[false, 'boolean'],
			[true, 'boolean'],
			['', 'string'],
			[{}, 'object'],
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

		// Handler
		const testType = function (value, typeExpected, typeActual) {
			it(`should detect ${util.inspect(value)} is of type ${typeExpected}`, function () {
				assert.equal(typeActual, typeExpected)
			})
		}

		// Run
		for ( let [value, typeExpected] of typeTestData ) {
			const typeActual = typeChecker.getType(value)
			testType(value, typeExpected, typeActual)
		}
	})

	describe('value', function (describe, it) {
		it('isPlainObject', function () {
			class A {}
			assert.equal(typeChecker.isPlainObject({}), true, 'object {} should be a plain object')
			assert.equal(typeChecker.isPlainObject(new A()), false, 'class A instantiation should not be a plain object')
		})

		it('isEmpty', function () {
			assert.equal(typeChecker.isEmpty(null), true, 'null should be considered empty')
			assert.equal(typeChecker.isEmpty(), true, 'undefined should be considered empty')
			assert.equal(typeChecker.isEmpty(false), false, 'false should not be considered empty')
			assert.equal(typeChecker.isEmpty(0), false, '0 should not be considered empty')
			assert.equal(typeChecker.isEmpty(''), false, '"" should not be considered empty')
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
			assert.equal(typeChecker.isEmptyObject({}), true, '{} should be considered empty')
			assert.equal(typeChecker.isEmptyObject({a: 1}), false, '{a: 1} should not be considered empty')
			assert.equal(typeChecker.isEmptyObject(new A()), true, 'class A instantiation should be considered empty')
			assert.equal(typeChecker.isEmptyObject(new B()), true, 'class B instantiation should not be considered empty')
			assert.equal(typeChecker.isEmptyObject(new C()), true, 'class C instantiation should be considered empty')
			assert.equal(typeChecker.isEmptyObject(new D()), false, 'class D instantiation should not be considered empty')
		})
	})
})
