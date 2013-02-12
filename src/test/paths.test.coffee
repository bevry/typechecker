# Requires
assert = require('assert')
joe = require('joe')
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

joe.describe 'paths', (describe,it) ->

	# ignoreCommonPatterns
	describe 'ignoreCommonPatterns', (describe,it) ->
		ignoreExpected = {
			# Vim
			"~": true
			"~something": true
			"something~": false
			"something~something": false

			# Emacs
			".#": true
			".#something": true
			"something.#": false
			"something.#something": false

			# Vi
			".swp": true
			"aswp": false
			"something.swp": true
			".swpsomething": false

			# SVN
			".svn": true
			"asvn": false
			"something.svn": false
			"something.svnsomething": false

			# GIT
			".git": true
			"agit": false
			"something.git": false
			"something.gitsomething": false

			# HG
			".hg": true
			"ahg": false
			"something.hg": false
			"something.hgsomething": false

			# DS_Store
			".DS_Store": true
			"something.DS_Store": false
			"something.DS_Storesomething": false

			# Node
			"node_modules": true
			"somethingnode_modules": false
			"somethingnode_modulessomething": false

			# CVS
			"CVS": true
			"somethingCVS": false
			"somethingCVSsomething": false

			# Thumbs
			"thumbs.db": true
			"thumbsadb": false

			# Desktop
			"desktop.ini": true
			"desktopaini": false
		}
		for own str,resultExpected of ignoreExpected
			testName = "#{if resultExpected then "should" else "should not"} ignore [#{str}]"
			it testName, ->
				resultActual = balUtil.testIgnorePatterns(str)
				assert.equal(resultActual, resultExpected)

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

	# Test rmdirDeep
	describe 'rmdirDeep', (describe,it) ->
		# Cleaup srcPath
		it 'should clean up the srcPath', (done) ->
			balUtil.rmdirDeep srcPath, (err) ->
				return done(err)  if err
				exists = balUtil.existsSync(srcPath)
				assert.equal(exists,false)
				done()

		# Cleanup outPath
		it 'should clean up the outPath', (done) ->
			balUtil.rmdirDeep outPath, (err) ->
				return done(err)  if err
				exists = balUtil.existsSync(outPath)
				assert.equal(exists,false)
				done()


	# Test readPath
	describe 'readPath', (describe,it) ->
		timeoutServerAddress = "127.0.0.1"
		timeoutServerPort = 9666
		timeoutServer = null

		# Normal
		it 'should read normal paths', (done) ->
			balUtil.readPath __filename, (err,data) ->
				return done(err)  if err
				assert.ok(data?)
				return done()

		# Should decode gzip
		describe 'gzip', (describe,it) ->
			it 'should read gzipped paths', (done) ->
				balUtil.readPath 'http://api.stackoverflow.com/1.0/users/130638/', (err,data) ->
					# Check
					if process.version.indexOf('v0.4') is 0
						assert.ok(err?)
						return done()

					# Continue
					return done(err)  if err
					assert.ok(data?)
					assert.equal(data[0],'{')
					return done()

		# Server
		it 'should create our timeout server', ->
			# Server
			timeoutServer = require('http').createServer((req,res) ->
				res.writeHead(200, {'Content-Type': 'text/plain'})
			)
			timeoutServer.listen(timeoutServerPort, timeoutServerAddress)

		# Timeout
		it 'should timeout requests after a while of inactivity (10s)', (done) ->
			second = 0
			interval = setInterval(
				-> console.log("... #{++second} seconds")
				1*1000
			)
			timeout = setTimeout(
				->
					assert.ok(false, 'timeout did not kick in')
					return done()
				15*1000
			)
			balUtil.readPath "http://#{timeoutServerAddress}:#{timeoutServerPort}", (err,data) ->
				clearInterval(interval)
				clearTimeout(timeout)
				assert.ok(err?, 'timeout executed correctly with error')
				return done()

		# Close Server
		it 'should close the server', ->
			timeoutServer.close()

