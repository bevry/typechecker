# Requires
assert = require('assert')
path = require('path')
balUtil = require(__dirname+'/../lib/balutil.coffee')


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


# -------------------------------------
# rmdir

describe 'rmdir', ->

	it 'should fail gracefully when the directory does not exist', (done) ->

		# rmdir
		balUtil.rmdir nonPath, (err) ->
			# There should be no error
			assert.equal(err||false, false)
			done()


# -------------------------------------
# Write Tree

# Test writetree
describe 'writetree', ->
	it 'should work as expected', (done) ->

		# Write the tree
		balUtil.writetree srcPath, writetree, (err) ->
			throw err  if err

			# Check if the tree was written correctly
			balUtil.scantree srcPath, (err,scantree) ->
				throw err  if err

				# Check if they match
				assert.deepEqual(scantree,writetree)

				# Done
				done()

				# Test cpdir
				describe 'cpdir', ->
					it 'should work as expected', (done) ->
						
						# Copy the source path to the out path
						balUtil.cpdir srcPath, outPath, (err) ->
							throw err  if err

							# Check if the tree was written correctly
							balUtil.scantree outPath, (err,scantree) ->
								throw err  if err

								# Check if they match
								assert.deepEqual(scantree,writetree)

								# Done
								done()

								# Test rmdir
								describe 'rmdir', ->
									# Cleaup srcPath
									it 'should clean up the srcPath', (done) ->
										balUtil.rmdir srcPath, (err) ->
											throw err  if err
											exists = path.existsSync(srcPath)
											assert.equal(exists,false)
											done()
									# Cleanup outPath
									it 'should clean up the outPath', (done) ->
										balUtil.rmdir outPath, (err) ->
											throw err  if err
											exists = path.existsSync(outPath)
											assert.equal(exists,false)
											done()

									
			
