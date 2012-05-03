# Requires
# none


# =====================================
# Types
# Provides higher level typeof functionality

type =
	# Get the type
	get: (value) ->
		# Prepare
		result = 'object'

		# Cycle
		for type in ['array','regex','function','boolean','number','string','null','undefined']
			if @[type] value
				result = type
				break
		
		# Return
		return result

	# Checks to see if a value is an object
	object: (value) ->
		return @get(value) is 'object'
		
	# Checks to see if a value is a function
	function: (value) ->
		return value instanceof Function

	# Checks to see if a value is an regex
	regex: (value) ->
		return value instanceof RegExp

	# Checks to see if a value is an array
	array: (value) ->
		return value instanceof Array

	# Checks to see if a valule is a boolean
	boolean: (value) ->
		return typeof value is 'boolean'
		#return value.toString() in ['false','true']

	# Checks to see if a valule is a number
	number: (value) ->
		return value? and typeof value.toPrecision isnt 'undefined'

	# Checks to see if a value is a string
	string: (value) ->
		return value? and typeof value.charAt isnt 'undefined'

	# Checks to see if a value is null
	'null': (value) ->
		return value is null

	# Checks to see if a value is undefined
	'undefined': (value) ->
		return typeof value is 'undefined'
	
	# Checks to see if a value is empty
	empty: (value) ->
		return value?


# =====================================
# Export

module.exports = {type}