// @ts-check
/* eslint-disable */

/** Get the object type string */
export function getObjectType(value: any): string

/** Checks to see if a value is an object */
export function isObject(value: any): boolean

/** Checks to see if a value is an object and only an object */
export function isPlainObject(value: any): boolean

/** Checks to see if a value is empty */
export function isEmpty(value: any): boolean

/** Is empty object */
export function isEmptyObject(value: any): boolean

/** Is ES6+ class */
export function isNativeClass(value: any): boolean

/**
 * Is Conventional Class
 * Looks for function with capital first letter MyClass
 * Firsetter is the 9th character
 * If changed, isClass must also be updated */
export function isConventionalClass(value: any): boolean

// -----------------------------------
// Types

/** Is Class */
export function isClass(value: any): boolean

/** Checks to see if a value is an error */
export function isError(value: any): boolean

/** Checks to see if a value is a date */
export function isDate(value: any): boolean

/** Checks to see if a value is an arguments object */
export function isArguments(value: any): boolean

/** Checks to see if a value is a function but not an asynchronous function */
export function isSyncFunction(value: any): boolean

/** Checks to see if a value is an asynchronous function */
export function isAsyncFunction(value: any): boolean

/** Checks to see if a value is a function */
export function isFunction(value: any): boolean

/** Checks to see if a value is an regex */
export function isRegExp(value: any): boolean

/** Checks to see if a value is an array */
export function isArray(value: any): boolean

/** Checks to see if a valule is a number */
export function isNumber(value: any): boolean

/** Checks to see if a value is a string */
export function isString(value: any): boolean

/** Checks to see if a valule is a boolean */
export function isBoolean(value: any): boolean

/** Checks to see if a value is null */
export function isNull(value: any): boolean

/** Checks to see if a value is undefined */
export function isUndefined(value: any): boolean

/** Checks to see if a value is a Map */
export function isMap(value: any): boolean

/** Checks to see if a value is a WeakMap */
export function isWeakMap(value: any): boolean

// -----------------------------------
// General

/**
 * The interface for methods that test for a particular type.
 * @param value The value that will have its type tested.
 * @returns Returns `true` if the value matches the type that the function tests against.
 */
type TypeTester = (value: any) => boolean

/**
 * The interface for a type mapping (key => function) to use for {@link getType}.
 * The key represents the name of the type. The function represents the {@link TypeTester test method}.
 * The map should be ordered by testing preference, with more specific tests first.
 * If a test returns true, it is selected, and the key is returned as the type.
 */
interface TypeMap {
	[type: string]: TypeTester
}

/**
 * The default {@link TypeMap} for {@link getType}.
 * AsyncFunction and SyncFunction are missing, as they are more specific types that people can detect afterwards.
 */
export const typeMap: TypeMap

/**
 * Cycle through the passed {@link TypeMap} testing the value, returning the first type that passes, otherwise `null`.
 * @param value the value to test
 * @param customTypeMap defaults to {@link typeMap}
 */
export function getType(value: any, customTypeMap?: TypeMap): string | null
