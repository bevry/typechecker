/* eslint quote-props:0 */

// Prepare
const isClassRegex = /^class\s|^function\s+[A-Z]/
const isConventionalClassRegex = /^function\s+[A-Z]/
const isNativeClassRegex = /^class\s/

/** Determines if the passed value is of a specific type */
export type TypeTester = (value: any) => boolean

/**
 * The interface for a type mapping (key => function) to use for {@link getType}.
 export * The key represents the name of the type. The function represents the {@link TypeTester test method}.
 * The map should be ordered by testing preference, with more specific tests first.
 * If a test returns true, it is selected, and the key is returned as the type.
 */
export interface TypeMap {
	[type: string]: TypeTester
}

export type AnyFunction = Function
export type Nullish = undefined | null
export type NonNullishObject = object // not null/undefined which are Object
export type NativeClass = abstract new (...args: any) => any
export type AnyNumber = number | Number
export type AnyString = string | String
export type AnyBoolean = boolean | Boolean
export type AnyArray = any[]
export type PlainObject = Record<any, {}> // https://stackoverflow.com/a/75052315/130638
export type AnyMap = Map<any, any>
export type AnyWeakMap = WeakMap<WeakKey, any>
export type EmptyArray = []

export type Any =
	| boolean
	| number
	| bigint
	| string
	| null
	| undefined
	| void
	| symbol
	| object
	| PlainObject
	| AnyArray
	| AnyMap
	| AnyWeakMap

// -----------------------------------
// Values

/** Get the object type string */
export function getObjectType(value?: any): string {
	return Object.prototype.toString.call(value)
}

/** Checks to see if a value is an object */
export function isObject(value: NonNullishObject): true
export function isObject(value?: Exclude<Any, NonNullishObject>): false
export function isObject(value?: any): value is NonNullishObject
export function isObject(value?: any): boolean {
	// null and undefined are objects, hence the extra check
	return value != null && typeof value === 'object'
}

/** Checks to see if a value is an object and only an object */
export function isPlainObject(value: PlainObject): true
export function isPlainObject(value?: Exclude<Any, PlainObject>): false
export function isPlainObject(value?: any): value is PlainObject
export function isPlainObject(value?: any): boolean {
	/* eslint no-proto:0 */
	// null and undefined are objects, hence the extra check
	return value != null && value.__proto__ === Object.prototype
}

/** Is ES6+ class */
export function isNativeClass(value: NativeClass): true
export function isNativeClass(value?: Exclude<Any, NativeClass>): false
export function isNativeClass(value?: any): value is NativeClass
export function isNativeClass(value?: any): boolean {
	// NOTE TO DEVELOPER: If any of this changes, isClass must also be updated
	return (
		typeof value === 'function' && isNativeClassRegex.test(value.toString())
	)
}

/**
 * Is Conventional Class
 * Looks for function with capital first letter MyClass
 * First letter is the 9th character
 * If changed, isClass must also be updated
 */
export function isConventionalClass(value: NativeClass): false
export function isConventionalClass(value: Function): boolean
export function isConventionalClass(value?: Exclude<Any, Function>): false
export function isConventionalClass(value?: any): value is Function // only guarantee of truth type, not of validity
export function isConventionalClass(value?: any): boolean {
	return (
		typeof value === 'function' &&
		isConventionalClassRegex.test(value.toString())
	)
}

// There use to be code here that checked for CoffeeScript's "function _Class" at index 0 (which was sound)
// But it would also check for Babel's __classCallCheck anywhere in the function, which wasn't sound
// as somewhere in the function, another class could be defined, which would provide a false positive
// So instead, proxied classes are ignored, as we can't guarantee their accuracy, would also be an ever growing set

// -----------------------------------
// Types

/** Is Class */
export function isClass(value: NativeClass): true
export function isClass(value: Function): boolean
export function isClass(value?: Exclude<Any, NativeClass | Function>): false
export function isClass(value?: any): value is NativeClass | Function // only guarantee of truth type, not of validity
export function isClass(value?: any): boolean {
	return typeof value === 'function' && isClassRegex.test(value.toString())
}

/** Checks to see if a value is an error */
export function isError(value: Error): true
export function isError(value?: Exclude<Any, Error>): false
export function isError(value?: any): value is Error
export function isError(value?: any): boolean {
	return value instanceof Error
}

/** Checks to see if a value is a date */
export function isDate(value: Date): true
export function isDate(value?: Exclude<Any, Date>): false
export function isDate(value?: any): value is Date
export function isDate(value?: any): boolean {
	return getObjectType(value) === '[object Date]'
}

/** Checks to see if a value is an arguments object */
export function isArguments(value: IArguments): true
export function isArguments(value?: Exclude<Any, IArguments>): false
export function isArguments(value?: any): value is IArguments
export function isArguments(value?: any): boolean {
	return getObjectType(value) === '[object Arguments]'
}

/** Checks to see if a value is a function but not an asynchronous function */
export function isSyncFunction(value: Function): boolean // can't use is, @todo figure out true/false check
export function isSyncFunction(value?: Exclude<Any, Function>): false
export function isSyncFunction(value?: any): value is Function // only guarantee of truth type, not of validity
export function isSyncFunction(value?: any): boolean {
	return getObjectType(value) === '[object Function]'
}

/** Checks to see if a value is an asynchronous function */
export function isAsyncFunction(value: Function): boolean // can't use is, @todo figure out true/false check
export function isAsyncFunction(value?: Exclude<Any, Function>): false
export function isAsyncFunction(value?: any): value is Function // only guarantee of truth type, not of validity
export function isAsyncFunction(value?: any): boolean {
	return getObjectType(value) === '[object AsyncFunction]'
}

/** Checks to see if a value is a function */
export function isFunction(value: Function): true
export function isFunction(value?: Exclude<Any, Function>): false
export function isFunction(value?: any): value is Function
export function isFunction(value?: any): boolean {
	return isSyncFunction(value) || isAsyncFunction(value)
}

/** Checks to see if a value is an regex */
export function isRegExp(value: RegExp): true
export function isRegExp(value?: Exclude<Any, RegExp>): false
export function isRegExp(value?: any): value is RegExp
export function isRegExp(value?: any): boolean {
	return getObjectType(value) === '[object RegExp]'
}

/** Checks to see if a value is an array */
export function isArray(value: AnyArray): true
export function isArray(value?: Exclude<Any, AnyArray>): false
export function isArray(value?: any): value is AnyArray
export function isArray(value?: any): boolean {
	return (
		(typeof Array.isArray === 'function' && Array.isArray(value)) ||
		getObjectType(value) === '[object Array]'
	)
}

/** Checks to see if a value is a number */
export function isNumber(value: AnyNumber): true
export function isNumber(value?: Exclude<Any, AnyNumber>): false
export function isNumber(value?: any): value is AnyNumber
export function isNumber(value?: any): boolean {
	return typeof value === 'number' || getObjectType(value) === '[object Number]'
}

/** Checks to see if a value is a string */
export function isString(value: AnyString): true
export function isString(value?: Exclude<Any, AnyString>): false
export function isString(value?: any): value is AnyString
export function isString(value?: any): boolean {
	return typeof value === 'string' || getObjectType(value) === '[object String]'
}

/** Checks to see if a value is a boolean */
export function isBoolean(value: AnyBoolean): true
export function isBoolean(value?: Exclude<Any, AnyBoolean>): false
export function isBoolean(value?: any): value is AnyBoolean
export function isBoolean(value?: any): boolean {
	return (
		value === true ||
		value === false ||
		getObjectType(value) === '[object Boolean]'
	)
}

/** Checks to see if a value is null */
export function isNull(value: null): true
export function isNull(value?: Exclude<Any, null>): false
export function isNull(value?: any): value is null
export function isNull(value?: any): boolean {
	return value === null
}

/** Checks to see if a value is undefined */
export function isUndefined(value?: undefined): true
export function isUndefined(value?: Exclude<Any, undefined>): false
export function isUndefined(value?: any): value is undefined
export function isUndefined(value?: any): boolean {
	return typeof value === 'undefined'
}

/** Checks to see if a value is nullish */
export function isNullish(value?: Nullish): true
export function isNullish(value?: Exclude<Any, Nullish>): false
export function isNullish(value?: any): value is Nullish
export function isNullish(value?: any): boolean {
	return value == null
}

/** Checks to see if a value is a Map */
export function isMap(value: AnyMap): true
export function isMap(value?: Exclude<Any, AnyMap>): false
export function isMap(value?: any): value is AnyMap
export function isMap(value?: any): boolean {
	return getObjectType(value) === '[object Map]'
}

/** Checks to see if a value is a WeakMap */
export function isWeakMap(value: AnyMap): false
export function isWeakMap(value: AnyWeakMap): true
export function isWeakMap(value?: Exclude<Any, AnyWeakMap>): false
export function isWeakMap(value?: any): value is AnyWeakMap
export function isWeakMap(value?: any): boolean {
	return getObjectType(value) === '[object WeakMap]'
}

// -----------------------------------
// Empty

/**
 * Is empty array
 * @throws if the value was not an array
 */
export function isEmptyArray(value: EmptyArray): true
export function isEmptyArray(value: AnyArray): false
export function isEmptyArray(value?: Exclude<Any, AnyArray>): never
export function isEmptyArray(value?: any): value is EmptyArray // only guarantee of truth type, not of validity
export function isEmptyArray(value?: any): boolean {
	if (!isArray(value)) throw new Error('value was not an array')
	return value.length === 0
}

/**
 * Is empty plain object
 * @throws if the value was not a plain object
 */
export function isEmptyPlainObject(value: PlainObject): boolean
export function isEmptyPlainObject(value?: Exclude<Any, PlainObject>): never
export function isEmptyPlainObject(value?: any): value is PlainObject // only guarantee of truth type, not of validity
export function isEmptyPlainObject(value?: any): boolean {
	if (!isPlainObject(value)) throw new Error('value was not a plain object')
	// We could use Object.keys, but this is more efficient
	for (const key in value) {
		if (value.hasOwnProperty(key)) {
			return false
		}
	}
	return true
}

/**
 * Is empty map
 * @throws if the value was not a Map
 */
export function isEmptyMap(value: AnyMap): boolean
export function isEmptyMap(value?: Exclude<Any, AnyMap>): never
export function isEmptyMap(value?: any): value is AnyMap // only guarantee of truth type, not of validity
export function isEmptyMap(value?: any): boolean {
	if (!isMap(value)) throw new Error('value was not a map')
	return value.size === 0
}
// const b1 = isEmptyMap(new Map())

/**
 * Is empty weak map
 * @throws if the value was not a WeakMap
 */
export function isEmptyWeakMap(value: AnyMap): never
export function isEmptyWeakMap(value: AnyWeakMap): boolean
export function isEmptyWeakMap(value?: Exclude<Any, AnyWeakMap>): never
export function isEmptyWeakMap(value?: any): value is AnyWeakMap // only guarantee of truth type, not of validity
export function isEmptyWeakMap(value?: any): boolean {
	if (!isWeakMap(value)) throw new Error('value was not a weak map')
	return Object.keys(value).length === 0
}

/** Is empty keys */
export function isEmptyKeys(value: EmptyArray): true
export function isEmptyKeys(value: AnyArray): false
export function isEmptyKeys(value: NonNullishObject): boolean
export function isEmptyKeys(value?: any): false
export function isEmptyKeys(value?: any): boolean {
	if (value == null) return false
	return Object.keys(value).length === 0
}

// -----------------------------------
// General

/**
 * The default {@link TypeMap} for {@link getType}.
 export * AsyncFunction and SyncFunction are missing, as they are more specific types that people can detect afterwards.
 * @readonly
 */
export const typeMap: TypeMap = Object.freeze({
	array: isArray,
	boolean: isBoolean,
	date: isDate,
	error: isError,
	class: isClass,
	function: isFunction,
	null: isNull,
	number: isNumber,
	regexp: isRegExp,
	string: isString,
	undefined: isUndefined,
	map: isMap,
	weakmap: isWeakMap,
	object: isObject,
})

/**
 * Cycle through the passed {@link TypeMap} testing the value, returning the first type that passes, otherwise `null`.
 * @param value the value to test
 * @param customTypeMap defaults to {@link typeMap}
 */
export function getType(
	value: any,
	customTypeMap: TypeMap = typeMap
): string | null {
	// Cycle through our type map
	for (const key in customTypeMap) {
		if (customTypeMap.hasOwnProperty(key)) {
			if (customTypeMap[key](value)) {
				return key
			}
		}
	}

	// No type was successful
	return null
}
