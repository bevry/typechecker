# Requires
assert = require('assert')
joe = require('joe')
balUtil = require(__dirname+'/../lib/balutil')


# =====================================
# Tests

# -------------------------------------
# Version Compare

joe.describe 'versionCompare', (describe,it) ->
	# Prepare
	versionCompareTestData = [
		['1.1.0', '<', '1.2.0', true]
		['1.2.0', '>', '1.1.0', true]
		['1.2.0', '==', '1.2.0', true]
		['1.2.0', '<=', '1.2.0', true]
		['1.2.0', '>=', '1.2.0', true]
		['1.2.0', '<', '1.2.1', true]
		['1.2.0', '<', '1.3.0', true]

		['1.1.0', '>=', '1.2.0', false]
		['1.2.0', '<=', '1.1.0', false]
		['1.2.0', '<>', '1.2.0', false]
		['1.2.0', '>', '1.2.0', false]
		['1.2.0', '<', '1.2.0', false]
		['1.2.0', '>=', '1.2.1', false]
		['1.2.0', '>=', '1.3.0', false]
	]

	# Handler
	testVersion = (v1,operator,v2,resultExpected,resultActual) ->
		it "should detect #{v1} #{operator} #{v2} is #{resultExpected}", ->
			assert.equal(resultActual,resultExpected)

	# Run
	for test in versionCompareTestData
		v1 = test[0]
		operator = test[1]
		v2 = test[2]
		resultExpected = test[3]
		resultActual = balUtil.versionCompare v1, operator, v2
		testVersion(v1,operator,v2,resultExpected,resultActual)


# -------------------------------------
# Package Compare

joe.describe 'packageCompare', (describe,it) ->
	# Check
	return it('test skipped for node v0.4', ->)  if process.version.indexOf('v0.4') is 0

	# Prepare
	localPackagePath = __dirname+'/../../package.json'
	remotePackagePath = 'https://raw.github.com/balupton/bal-util/master/package.json'

	# Handler
	testVersion = (v1,operator,v2) ->
		resultActual = balUtil.versionCompare(v1, operator, v2)
		assert.equal(resultActual,true)

	# Run
	it 'should run as expected', (done) ->
		balUtil.packageCompare(
			local: localPackagePath
			remote: remotePackagePath
			newVersionCallback: (details) ->
				testVersion(details.local.version,'<',details.remote.version)
				done()
			sameVersionCallback: (details) ->
				testVersion(details.local.version,'==',details.remote.version)
				done()
			oldVersionCallback: (details) ->
				testVersion(details.local.version,'>',details.remote.version)
				done()
			errorCallback: (err,data) ->
				return done(err)
		)
