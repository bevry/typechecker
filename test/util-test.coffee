# Requires
assert = require 'assert'
util = require __dirname+'/../lib/util.coffee'
path = require 'path'
cwd = process.cwd()

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
types = [
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
expandedpathssrc = [
	'a'
	'.b'
	'./b'
	'a/b'
	'./a/b'
	'./a/.b'
	'/a/b'
	'/a/.b'
]
expandedpathsresult1 = [
	__dirname+'/a'
	__dirname+'/.b'
	__dirname+'/./b'
	__dirname+'/a/b'
	__dirname+'/./a/b'
	__dirname+'/./a/.b'
	'/a/b'
	'/a/.b'
]
expandedpathsresult2 = [
	__dirname+'/a'
	cwd+'/.b'
	cwd+'/./b'
	__dirname+'/a/b'
	cwd+'/./a/b'
	cwd+'/./a/.b'
	'/a/b'
	'/a/.b'
]

# Tests
tests =

	'group': (beforeExit) ->
		# prepare
		nTests = 3
		nTestsCompleted = 0
		
		# Group
		tasks = new util.Group ->
			++nTestsCompleted
		tasks.total = 2
		
		# Push
		setTimeout(
			->
				assert.equal(1, nTestsCompleted, 'group: tasks have run in the correct order 2')
				++nTestsCompleted
				tasks.complete()
			1000
		)

		# Push
		setTimeout(
			->
				assert.equal(0, nTestsCompleted, 'group: tasks have run in the correct order 1')
				++nTestsCompleted
				tasks.complete()
			500
		)
		
		# Check
		assert.equal(0, nTestsCompleted, 'group: all tasks haven\'t run yet')

		# Async
		beforeExit ->
			assert.equal(nTests, nTestsCompleted, 'group: all tasks ran')


	'group-async': (beforeExit) ->
		# prepare
		nTests = 3
		nTestsCompleted = 0
		
		# Group
		tasks = new util.Group ->
			++nTestsCompleted
		
		# Push
		tasks.push ->
			setTimeout(
				->
					assert.equal(1, nTestsCompleted, 'group-async: tasks have run in the correct order 2')
					++nTestsCompleted
					tasks.complete()
				1000
			)

		# Push
		tasks.push ->
			assert.equal(0, nTestsCompleted, 'group-async: tasks have run in the correct order 1')
			++nTestsCompleted
			tasks.complete()
		
		# Check
		assert.equal(0, nTestsCompleted, 'group-async: all tasks haven\'t run yet')

		# Run
		tasks.async()

		# Async
		beforeExit ->
			assert.equal(nTests, nTestsCompleted, 'group-async: all tasks ran')


	'group-sync': (beforeExit) ->
		# prepare
		nTests = 3
		nTestsCompleted = 0
		
		# Group
		tasks = new util.Group ->
			++nTestsCompleted
		
		# Push
		tasks.push ->
			setTimeout(
				->
					assert.equal(0, nTestsCompleted, 'group-sync: tasks have run in the correct order 1')
					++nTestsCompleted
					tasks.complete()
				500
			)

		# Push
		tasks.push ->
			assert.equal(1, nTestsCompleted, 'group-sync: tasks have run in the correct order 2')
			++nTestsCompleted
			tasks.complete()
		
		# Check
		assert.equal(0, nTestsCompleted, 'group-sync: all tasks haven\'t run yet')

		# Run
		tasks.sync()

		# Async
		beforeExit ->
			assert.equal(nTests, nTestsCompleted, 'group-sync: all tasks ran')

	'parallel': (beforeExit) ->
		# prepare
		nTests = 3
		nTestsCompleted = 0
		
		# expandPaths
		util.parallel \
			# Tasks
			[
				(next) ->
					++nTestsCompleted
					next()
				(next) ->
					++nTestsCompleted
					next()
			],
			# Completed
			(err) ->
				assert.equal(2, nTestsCompleted, 'parallel: both tasks ran')
				++nTestsCompleted

		# async
		beforeExit ->
			assert.equal(nTests, nTestsCompleted, 'parallel: all tasks ran')

	'parallel-negative': (beforeExit) ->
		# prepare
		nTests = 1
		nTestsCompleted = 0
		err = new Error('deliberate fail')
		
		# expandPaths
		util.parallel \
			# Tasks
			[
				(next) ->
					next err
				(next) ->
					next err
			],
			# Completed
			(err) ->
				++nTestsCompleted

		# async
		beforeExit ->
			assert.equal(nTests, nTestsCompleted, 'parallel-negative: exited correctly')

	'expandpaths': (beforeExit) ->
		# prepare
		nTests = 2
		nTestsCompleted = 0

		# expandPaths
		util.expandPaths expandedpathssrc, __dirname, {}, (err,expandedPaths) ->
			++nTestsCompleted

			# no error
			assert.equal(err||false,false, 'expandpaths: 1: no error')
			
			# files were written
			assert.deepEqual(expandedPaths,expandedpathsresult1, 'expandpaths: 1: files were expanded')
			
		# expandPaths
		util.expandPaths expandedpathssrc, __dirname, {cwd:true}, (err,expandedPaths) ->
			++nTestsCompleted

			# no error
			assert.equal(err||false,false, 'expandpaths: 2: no error')
			
			# files were written
			assert.deepEqual(expandedPaths,expandedpathsresult2, 'expandpaths: 2: files were expanded')
		
		# async
		beforeExit ->
			assert.equal(nTests, nTestsCompleted, 'expandpaths: all tests ran')

	'type': ->
		for [value,type] in types
			determinedType = util.type.get(value)
			assert.equal determinedType, type, 'type: '+type+' ['+determinedType+']'


	'writetree': (beforeExit) ->
		# prepare
		nTests = 6
		nTestsCompleted = 0

		# writetree
		util.writetree srcPath, writetree, (err) ->
			++nTestsCompleted

			# no error
			assert.equal(err||false,false, 'writetree: no error')
			
			# scandir
			util.scandir srcPath, false, false, (err,list,tree) ->
				++nTestsCompleted
				
				# no error
				assert.equal(err||false,false, 'writetree: scandir: no error')
				
				# files were written
				assert.deepEqual(tree,scantree, 'writetree: scandir: files were written')
				
				# cpdir
				util.cpdir srcPath, outPath, (err) ->
					++nTestsCompleted
					
					# no error
					assert.equal(err||false,false, 'writree: scandir: cpdir: no error')
						
					# scandir
					util.scandir outPath, false, false, (err,list,tree) ->
						++nTestsCompleted
						
						# no error
						assert.equal(err||false,false, 'writree: scandir: cpdir: scandir: no error')
						
						# files were copied
						assert.deepEqual(tree,scantree, 'writree: scandir: cpdir: scandir: files were copied')

						# rmdir
						util.rmdir srcPath, (err) ->
							++nTestsCompleted
						
							# no error
							assert.equal(err||false,false, 'writree: scandir: cpdir: scandir: rmdir: no error')
						
							# dir was deleted
							exists = path.existsSync(srcPath)
							assert.equal(exists,false, 'writree: scandir: cpdir: scandir: rmdir: delete successful')

						# rmdir
						util.rmdir outPath, (err) ->
							++nTestsCompleted
							
							# no error
							assert.equal(err||false,false, 'writree: scandir: cpdir: scandir: rmdir: no error')
							
							# dir was deleted
							exists = path.existsSync(outPath)
							assert.equal(exists,false, 'writree: scandir: cpdir: scandir: rmdir: delete successful')

		# async
		beforeExit ->
			assert.equal(nTests, nTestsCompleted, 'writetree: all tests ran')


	'rmdir-non': (beforeExit) ->
		nTests = 1
		nTestsCompleted = 0
		
		# rmdir
		util.rmdir nonPath, (err) ->
			++nTestsCompleted
			# no error
			assert.equal(err||false,false, 'rmdir-non: no error')
		
		# async
		beforeExit ->
			assert.equal(nTests, nTestsCompleted, 'rmdir-non: all tests ran')
	

	'versionCompare': (beforeExit) ->
		tests = [
			['1.1.0', '<', '1.2.0', true]
			['1.2.0', '>', '1.1.0', true]
			['1.2.0', '<=', '1.2.0', true]
			['1.2.0', '>=', '1.2.0', true]
			['1.2.0', '<', '1.2.1', true]
			['1.2.0', '<', '1.3.0', true]
		]

		for test in tests
			v1 = test[0]
			operator = test[1]
			v2 = test[2]
			expected = test[3]

			actual = util.versionCompare v1, operator, v2

			assert.equal actual, expected, "versionCompare: comparison of #{v1} #{operator} #{v2} failed"
	
	"comparePackages": (beforeExit) ->
		compareHappened = false

		util.packageCompare(
			local: "#{__dirname}/../package.json"
			remote: 'https://raw.github.com/balupton/bal-util.npm/master/package.json'
			newVersionCallback: (details) ->
				compareHappened = true
			oldVersionCallback: (details) ->
				compareHappened = true
			errorCallback: (err) ->
				console.log err
				assert.ok false, 'an error occured during comparePackages'
		)

		beforeExit = ->
			assert.equal compareHappened, true, 'compare actually happened'

# Export
module.exports = tests