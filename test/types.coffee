# Requires
assert = require('assert')
util = require(__dirname+'/../lib/util.coffee')
nodeUtil = require('util')


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
		it "should detect #{nodeUtil.inspect value} is of type #{typeExpected}", ->
			assert.equal(typeActual,typeExpected)
	
	# Run
	for [value,typeExpected] in typeTestData
		typeActual = util.type.get(value)
		testType(value,typeExpected,typeActual)

