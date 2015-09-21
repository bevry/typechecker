// Types
const types = [
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

// Module
const typeChecker = {

	// -----------------------------------
	// Helpers

	// Get the object type string
	getObjectType: function (value) {
		return Object.prototype.toString.call(value)
	},

	// Get the type
	getType: function (value) {
		// Cycle
		for ( let i = 0, n = types.length, type; i < n; ++i ) {
			type = types[i]
			if ( typeChecker['is' + type](value) ) {
				return type.toLowerCase()
			}
		}

		// Return
		return null
	},

	// -----------------------------------
	// Values

	// Checks to see if a value is an object and only an object
	isPlainObject: function (value) {
		/* eslint no-proto:0 */
		return typeChecker.isObject(value) && value.__proto__ === Object.prototype
	},

	// Checks to see if a value is empty
	isEmpty: function (value) {
		return value == null
	},

	// Is empty object
	isEmptyObject: function (value) {
		// We could use Object.keys, but this is more effecient
		for ( let key in value ) {
			if ( value.hasOwnProperty(key) ) {
				return false
			}
		}
		return true
	},

	// Is ES6+ class
	// If changed, isClass must also be updated
	isNativeClass: function (value) {
		return typeof value === 'function' && value.toString().indexOf('class') === 0
	},

	// Is Conventional Class
	// Looks for function with capital first letter: function MyClass
	// First letter is the 9th character
	// Uppercase letters are between 65 and 90 inclusive
	// If changed, isClass must also be updated
	isConventionalClass: function (value) {
		let c; return typeof value === 'function' && (c = value.toString().charCodeAt(9)) >= 65 && c <= 90
	},

	// There use to be code here that checked for CoffeeScript's "function _Class" at index 0 (which was sound)
	// But it would also check for Babel's __classCallCheck anywhere in the function, which wasn't sound
	// as somewhere in the function, another class could be defined, which would provide a false positive
	// So instead, proxied classes are ignored, as we can't guarantee their accuracy, would also be an ever growing set


	// -----------------------------------
	// Types

	// Is Class
	isClass: function (value) {
		/* eslint no-extra-parens:0 */
		let s, c; return typeof value === 'function' && (
			(s = value.toString()).indexOf('class') === 0 ||
			((c = s.charCodeAt(9)) >= 65 && c <= 90)
		)
	},

	// Checks to see if a value is an object
	isObject: function (value) {
		// null and undefined are objects, hence the truthy check
		return value && typeof value === 'object'
	},

	// Checks to see if a value is an error
	isError: function (value) {
		return value instanceof Error
	},

	// Checks to see if a value is a date
	isDate: function (value) {
		return typeChecker.getObjectType(value) === '[object Date]'
	},

	// Checks to see if a value is an arguments object
	isArguments: function (value) {
		return typeChecker.getObjectType(value) === '[object Arguments]'
	},

	// Checks to see if a value is a function
	isFunction: function (value) {
		return typeChecker.getObjectType(value) === '[object Function]'
	},

	// Checks to see if a value is an regex
	isRegExp: function (value) {
		return typeChecker.getObjectType(value) === '[object RegExp]'
	},

	// Checks to see if a value is an array
	isArray: function (value) {
		return Array.isArray && Array.isArray(value) || typeChecker.getObjectType(value) === '[object Array]'
	},

	// Checks to see if a valule is a number
	isNumber: function (value) {
		return typeof value === 'number' || typeChecker.getObjectType(value) === '[object Number]'
	},

	// Checks to see if a value is a string
	isString: function (value) {
		return typeof value === 'string' || typeChecker.getObjectType(value) === '[object String]'
	},

	// Checks to see if a valule is a boolean
	isBoolean: function (value) {
		return value === true || value === false || typeChecker.getObjectType(value) === '[object Boolean]'
	},

	// Checks to see if a value is null
	isNull: function (value) {
		return value === null
	},

	// Checks to see if a value is undefined
	isUndefined: function (value) {
		return typeof value === 'undefined'
	},

	// Checks to see if a value is a Map
	isMap: function (value) {
		return typeChecker.getObjectType(value) === '[object Map]'
	},

	// Checks to see if a value is a WeakMap
	isWeakMap: function (value) {
		return typeChecker.getObjectType(value) === '[object WeakMap]'
	}

}

// Export
export default typeChecker
