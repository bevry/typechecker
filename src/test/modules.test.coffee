# Requires
assert = require('assert')
joe = require('joe')
balUtil = require(__dirname+'/../lib/balutil')

# Local Globals
travis = process.env.TRAVIS_NODE_VERSION?

# =====================================
# Tests

joe.describe 'modules', (describe,it) ->

	describe 'requireFresh', (describe,it) ->
		it 'should fetch something', ->
			result = balUtil.requireFresh(__dirname+'/../../package.json')
			assert.ok(result)
			assert.ok(result?.version)

	describe 'locale', (describe,it) ->
		describe 'getLocaleCode', (describe,it) ->
			it 'should fetch something', ->
				localeCode = balUtil.getLocaleCode()
				console.log('localeCode:', localeCode)
				assert.ok(localeCode)

			it 'should fetch something when passed something', ->
				localeCode = balUtil.getLocaleCode('fr-CH')
				assert.equal(localeCode, 'fr_ch')
				localeCode = balUtil.getLocaleCode('fr_CH')
				assert.equal(localeCode, 'fr_ch')

		describe 'getCountryCode', (describe,it) ->
			it 'should fetch something', ->
				countryCode = balUtil.getCountryCode()
				console.log('countryCode:', countryCode)
				assert.ok(countryCode)

			it 'should fetch something when passed something', ->
				countryCode = balUtil.getCountryCode('fr-CH')
				assert.equal(countryCode, 'ch')

		describe 'getLanguageCode', (describe,it) ->
			it 'should fetch something', ->
				languageCode = balUtil.getLanguageCode()
				console.log('languageCode:', languageCode)
				assert.ok(languageCode)

			it 'should fetch something when passed something', ->
				languageCode = balUtil.getLanguageCode('fr-CH')
				assert.equal(languageCode, 'fr')

	describe 'getHomePath', (describe,it) ->
		it 'should fetch something', (done) ->
			balUtil.getHomePath (err,path) ->
				assert.equal(err||null, null)
				console.log('home:',path)
				assert.ok(path)
				done()

	describe 'getTmpPath', (describe,it) ->
		it 'should fetch something', (done) ->
			balUtil.getTmpPath (err,path) ->
				assert.equal(err||null, null)
				console.log('tmp:',path)
				assert.ok(path)
				done()

	describe 'getGitPath', (describe,it) ->
		it 'should fetch something', (done) ->
			balUtil.getGitPath (err,path) ->
				assert.equal(err||null, null)
				console.log('git:',path)
				assert.ok(path)
				done()

	describe 'getNodePath', (describe,it) ->
		it 'should fetch something', (done) ->
			balUtil.getNodePath (err,path) ->
				assert.equal(err||null, null)
				console.log('node:',path)
				assert.ok(path)
				done()

	describe 'getNpmPath', (describe,it) ->
		it 'should fetch something', (done) ->
			balUtil.getNpmPath (err,path) ->
				assert.equal(err||null, null)
				console.log('npm:',path)
				assert.ok(path)
				done()

	describe 'getExecPath', (describe,it) ->
		it 'should fetch something', (done) ->
			balUtil.getExecPath 'ruby', (err,path) ->
				assert.equal(err||null, null)
				console.log('ruby:',path)
				assert.ok(path)
				done()