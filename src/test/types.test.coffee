# Requires
assert = require('assert')
joe = require('joe')
balUtil = require(__dirname+'/../lib/balutil')
util = require('util')


# =====================================
# Tests

# Types
joe.describe 'types', (describe,it) ->
	# Prepare
	typeTestData = [
		[false,'boolean']
		[true,'boolean']
		['','string']
		[{},'object']
		[(->),'function']
		[new Date(),'date']
		[new Error(),'error']
		[[],'array']
		[null,'null']
		[undefined,'undefined']
		[/a/,'regexp']
		[1,'number']
	]

	# Handler
	testType = (value,typeExpected,typeActual) ->
		it "should detect #{util.inspect value} is of type #{typeExpected}", ->
			assert.equal(typeActual,typeExpected)

	# Run
	for [value,typeExpected] in typeTestData
		typeActual = balUtil.getType(value)
		testType(value,typeExpected,typeActual)

