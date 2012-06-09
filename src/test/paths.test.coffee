# Requires
assert = require('assert')
path = require('path')
balUtil = require(__dirname+'/../lib/balutil')


# =====================================
# Configuration

# Test Data
srcPath = __dirname+'/src'
outPath = __dirname+'/out'
nonPath = __dirname+'/asd'
writetree =
	'index.html': '<html>'
	'blog':
		'post1.md': 'my post'
		'post2.md': 'my post2'
	'styles':
		'style.css': 'blah'
		'themes':
			'balupton':
				'style.css': 'body { display:none; }'
			'style.css': 'blah'
###
scantree =
	'index.html': true
	'blog':
		'post1.md': true
		'post2.md': true
	'styles':
		'style.css': true
		'themes':
			'balupton':
				'style.css': true
			'style.css': true
###


# =====================================
# Tests

describe 'paths', (describe,it) ->

	# Test rmdir
	describe 'rmdir', (describe,it) ->
		it 'should fail gracefully when the directory does not exist', (done) ->
			# rmdir
			balUtil.rmdirDeep nonPath, (err) ->
				assert.equal(err||null, null)
				done()

	# Test writetree
	describe 'writetree', (describe,it) ->
		it 'should fire without error', (done) ->
			# Write the tree
			balUtil.writetree srcPath, writetree, (err) ->
				return done(err)

		# Check if the tree was written correctly
		it 'should write the files correctly', (done) ->
			balUtil.scantree srcPath, (err,scantree) ->
				return done(err)  if err
				assert.deepEqual(scantree,writetree)
				done()

	# Test cpdir
	describe 'cpdir', (describe,it) ->
		it 'should fire without error', (done) ->
			# Copy the source path to the out path
			balUtil.cpdir srcPath, outPath, (err) ->
				return done(err)

		# Check if the tree was written correctly
		it 'should write the files correctly', (done) ->
			balUtil.scantree outPath, (err,scantree) ->
				return done(err)  if err
				assert.deepEqual(scantree,writetree)
				done()

	# Test rmdir
	describe 'rmdirDeep', (describe,it) ->
		# Cleaup srcPath
		it 'should clean up the srcPath', (done) ->
			balUtil.rmdirDeep srcPath, (err) ->
				return done(err)  if err
				exists = path.existsSync(srcPath)
				assert.equal(exists,false)
				done()

		# Cleanup outPath
		it 'should clean up the outPath', (done) ->
			balUtil.rmdirDeep outPath, (err) ->
				return done(err)  if err
				exists = path.existsSync(outPath)
				assert.equal(exists,false)
				done()
