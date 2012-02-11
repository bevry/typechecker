# Requires
assert = require('assert')
balUtil = require(__dirname+'/../lib/balutil.coffee')
util = require('util')


# =====================================
# Tests

# -------------------------------------
# Types

describe 'type', ->
	# Prepare
	typeTestData = [
		[false,'boolean']
		[true,'boolean']
		['','string']
		[{},'object']
		[(->),'function']
		[null,'null']
		[undefined,'undefined']
		[/a/,'regex']
		[1,'number']
	]

	# Handler
	testType = (value,typeExpected,typeActual) ->
		it "should detect #{util.inspect value} is of type #{typeExpected}", ->
			assert.equal(typeActual,typeExpected)
	
	# Run
	for [value,typeExpected] in typeTestData
		typeActual = balUtil.type.get(value)
		testType(value,typeExpected,typeActual)

