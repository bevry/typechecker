'use strict'

// Character positions
const INDEX_OF_FUNCTION_NAME = 9  // "function X", X is at index 9
const FIRST_UPPERCASE_INDEX_IN_ASCII = 65  // A is at index 65 in ASCII
const LAST_UPPERCASE_INDEX_IN_ASCII = 90   // Z is at index 90 in ASCII

// Module
module.exports = class TypeChecker {
	// -----------------------------------
	// Helpers

	// Get an array of the available types in CamelCase
	static getTypes () {
		return [
			'Array',
			'Boolean',
			'Date',
			'Error',
			'Class',
			'Function',
			'Null',
			'Number',
			'RegExp',
			'String',
			'Undefined',
			'Map',
			'WeakMap',
			'Object'  // deliberately last, as this is a catch all
		]
	}

	// Get the type of the value in lowercase
	static getType (value) {
		// Cycle the keys of this class
		const types = this.getTypes()
		for ( let i = 0; i < types.length; ++i ) {
			const type = types[i]
			if ( this['is' + type](value) ) {
				return type.toLowerCase()
			}
		}

		// Return
		return null
	}

	// Get the object type string
	static getObjectType (value) {
		return Object.prototype.toString.call(value)
	}

	// -----------------------------------
	// Values

	// Checks to see if a value is an object and only an object
	static isPlainObject (value) {
		/* eslint no-proto:0 */
		return this.isObject(value) && value.__proto__ === Object.prototype
	}

	// Checks to see if a value is empty
	static isEmpty (value) {
		return value == null
	}

	// Is empty object
	static isEmptyObject (value) {
		// We could use Object.keys, but this is more effecient
		for ( const key in value ) {
			if ( value.hasOwnProperty(key) ) {
				return false
			}
		}
		return true
	}

	// Is ES6+ class
	// If changed, isClass must also be updated
	static isNativeClass (value) {
		return typeof value === 'function' && value.toString().indexOf('class') === 0
	}

	// Is Conventional Class
	// Looks for function with capital first letter MyClass
	// First letter is the 9th character
	// If changed, isClass must also be updated
	static isConventionalClass (value) {
		let c; return typeof value === 'function' &&
			(c = value.toString().charCodeAt(INDEX_OF_FUNCTION_NAME)) >= FIRST_UPPERCASE_INDEX_IN_ASCII
				&& c <= LAST_UPPERCASE_INDEX_IN_ASCII
	}

	// There use to be code here that checked for CoffeeScript's "function _Class" at index 0 (which was sound)
	// But it would also check for Babel's __classCallCheck anywhere in the function, which wasn't sound
	// as somewhere in the function, another class could be defined, which would provide a false positive
	// So instead, proxied classes are ignored, as we can't guarantee their accuracy, would also be an ever growing set


	// -----------------------------------
	// Types

	// Is Class
	static isClass (value) {
		/* eslint no-extra-parens:0 */
		let s, c; return typeof value === 'function' && (
			(s = value.toString()).indexOf('class') === 0 ||
			((c = s.charCodeAt(INDEX_OF_FUNCTION_NAME)) >= FIRST_UPPERCASE_INDEX_IN_ASCII
				&& c <= LAST_UPPERCASE_INDEX_IN_ASCII)
		)
	}

	// Checks to see if a value is an object
	static isObject (value) {
		// null and undefined are objects, hence the truthy check
		return value && typeof value === 'object'
	}

	// Checks to see if a value is an error
	static isError (value) {
		return value instanceof Error
	}

	// Checks to see if a value is a date
	static isDate (value) {
		return this.getObjectType(value) === '[object Date]'
	}

	// Checks to see if a value is an arguments object
	static isArguments (value) {
		return this.getObjectType(value) === '[object Arguments]'
	}

	// Checks to see if a value is a function
	static isFunction (value) {
		return this.getObjectType(value) === '[object Function]'
	}

	// Checks to see if a value is an regex
	static isRegExp (value) {
		return this.getObjectType(value) === '[object RegExp]'
	}

	// Checks to see if a value is an array
	static isArray (value) {
		return Array.isArray && Array.isArray(value) || this.getObjectType(value) === '[object Array]'
	}

	// Checks to see if a valule is a number
	static isNumber (value) {
		return typeof value === 'number' || this.getObjectType(value) === '[object Number]'
	}

	// Checks to see if a value is a string
	static isString (value) {
		return typeof value === 'string' || this.getObjectType(value) === '[object String]'
	}

	// Checks to see if a valule is a boolean
	static isBoolean (value) {
		return value === true || value === false || this.getObjectType(value) === '[object Boolean]'
	}

	// Checks to see if a value is null
	static isNull (value) {
		return value === null
	}

	// Checks to see if a value is undefined
	static isUndefined (value) {
		return typeof value === 'undefined'
	}

	// Checks to see if a value is a Map
	static isMap (value) {
		return this.getObjectType(value) === '[object Map]'
	}

	// Checks to see if a value is a WeakMap
	static isWeakMap (value) {
		return this.getObjectType(value) === '[object WeakMap]'
	}

}
