# Define
typeChecker =

	# Get the object type string
	getObjectType: (value) ->
		return Object::toString.call(value)

	# Get the type
	getType: (value) ->
		# Prepare
		result = 'object'

		# Cycle
		for type in ['Array','RegExp','Date','Function','Boolean','Number','Error','String','Null','Undefined']
			if typeChecker['is'+type](value)
				result = type.toLowerCase()
				break

		# Return
		return result

	# Checks to see if a value is an object and only an object
	isPlainObject: (value) ->
		return typeChecker.isObject(value) and value.__proto__ is Object.prototype

	# Checks to see if a value is an object
	isObject: (value) ->
		# null and undefined are objects, hence the truthy check
		return value and typeof value is 'object'

	# Checks to see if a value is an error
	isError: (value) ->
		return value instanceof Error

	# Checks to see if a value is a date
	isDate: (value) ->
		return typeChecker.getObjectType(value) is '[object Date]'

	# Checks to see if a value is an arguments object
	isArguments: (value) ->
		return typeChecker.getObjectType(value) is '[object Arguments]'

	# Checks to see if a value is a function
	isFunction: (value) ->
		return typeChecker.getObjectType(value) is '[object Function]'

	# Checks to see if a value is an regex
	isRegExp: (value) ->
		return typeChecker.getObjectType(value) is '[object RegExp]'

	# Checks to see if a value is an array
	isArray: (value) ->
		return Array.isArray?(value) ? typeChecker.getObjectType(value) is '[object Array]'

	# Checks to see if a valule is a number
	isNumber: (value) ->
		return typeof value is 'number' or typeChecker.getObjectType(value) is '[object Number]'

	# Checks to see if a value is a string
	isString: (value) ->
		return typeof value is 'string' or typeChecker.getObjectType(value) is '[object String]'

	# Checks to see if a valule is a boolean
	isBoolean: (value) ->
		return value is true or value is false or typeChecker.getObjectType(value) is '[object Boolean]'

	# Checks to see if a value is null
	isNull: (value) ->
		return value is null

	# Checks to see if a value is undefined
	isUndefined: (value) ->
		return typeof value is 'undefined'

	# Checks to see if a value is empty
	isEmpty: (value) ->
		return value?

	# Is empty object
	isEmptyObject: (value) ->
		empty = true
		if value?
			for own key,value of value
				empty = false
				break
		return empty


# Export
module.exports = typeChecker