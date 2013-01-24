# Requires
assert = require('assert')
joe = require('joe')
balUtil = require(__dirname+'/../lib/balutil')

# Local Globals
travis = process.env.TRAVIS_NODE_VERSION?

# =====================================
# Tests

joe.describe 'modules', (describe,it) ->

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