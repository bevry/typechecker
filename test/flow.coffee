# Requires
assert = require('assert')
balUtil = require(__dirname+'/../lib/balutil.coffee')


# =====================================
# Tests

# -------------------------------------
# Flow

describe 'flow', ->

	it 'should detect arrays', (done) ->
		# Prepare
		arr = []
		obj = {}
		str = ''
		assert.equal(true,balUtil.isArray(arr), 'array vs array comparison')
		assert.equal(false,balUtil.isArray(obj), 'object vs array comparison')
		assert.equal(false,balUtil.isArray(str), 'string vs array comparison')
		done()

	it 'should cycle arrays', (done) ->
		# Prepare
		arr = ['a','b','c']
		out = []
		balUtil.each arr, (value,key) ->
			out[key] = value
		assert.deepEqual(arr,out, 'cycling an array produced the expected results')
		done()

	it 'should cycle objects', (done) ->
		# Prepare
		obj = {'a':1,'b':2,'c':3}
		out = {}
		balUtil.each obj, (value,key) ->
			out[key] = value
		assert.deepEqual(obj,out, 'cycling an object produced the expected results')
		done()


# -------------------------------------
# Group

describe 'Group', ->

	it 'should work when tasks are specified manually', (done) ->
		# Prepare
		@timeout(2200)
		tasks = null
		tasksExpected = 2
		tasksCompleted = 0

		# Create our group
		tasks = new balUtil.Group ->
			assert.equal(tasksExpected, tasksCompleted, 'the group of tasks finished with the expected tasks completing')
		tasks.total = tasksExpected
	
		# Make the first task finish after the second task
		setTimeout(
			->
				assert.equal(1, tasksCompleted, 'the first task finished last as expected')
				++tasksCompleted
				tasks.complete()
			1000
		)

		# Make the second task finish before the first task
		setTimeout(
			->
				assert.equal(0, tasksCompleted, 'the second task finished first as expected')
				++tasksCompleted
				tasks.complete()
			500
		)
		
		# Check no tasks have run
		assert.equal(0, tasksCompleted, 'no tasks should have started yet')

		# Check all tasks ran
		setTimeout(
			->
				assert.equal(tasksExpected, tasksCompleted, 'only the expected number of tasks ran')
				done()
			2000
		)

	it 'should work when run synchronously', (done) ->
		# Prepare
		@timeout(2200)
		tasks = null
		tasksExpected = 2
		tasksCompleted = 0

		# Create our group
		tasks = new balUtil.Group ->
			assert.equal(tasksExpected, tasksCompleted, 'the group of tasks finished with the expected tasks completing')
		tasks.total = tasksExpected
	
		# Make the first task take longer than the second task, but as we run synchronously, it should still finish first
		tasks.push (next) ->
			setTimeout(
				->
					assert.equal(0, tasksCompleted, 'the first task finished first as expected')
					++tasksCompleted
					next()
				1000
			)

		# Make the second task take shorter than the first task, but as we run synchronously, it should still finish second
		tasks.push (next) ->
			setTimeout(
				->
					assert.equal(1, tasksCompleted, 'the second task finished last as expected')
					++tasksCompleted
					next()
				500
			)
		
		# Check no tasks have run
		assert.equal(0, tasksCompleted, 'no tasks should have started yet')
		
		# Run the tasks
		tasks.sync()

		# Check all tasks ran
		setTimeout(
			->
				assert.equal(tasksExpected, tasksCompleted, 'only the expected number of tasks ran')
				done()
			2000
		)


	it 'should work when run asynchronously', (done) ->
		# Prepare
		@timeout(2200)
		tasks = null
		tasksExpected = 2
		tasksCompleted = 0

		# Create our group
		tasks = new balUtil.Group ->
			assert.equal(tasksExpected, tasksCompleted, 'the group of tasks finished with the expected tasks completing')
		tasks.total = tasksExpected
	
		# Make the first task take longer than the second task, and as we run asynchronously, it should finish last
		tasks.push (next) ->
			setTimeout(
				->
					assert.equal(1, tasksCompleted, 'the first task finished last as expected')
					++tasksCompleted
					next()
				1000
			)

		# Make the second task take shorter than the first task, and as we run asynchronously, it should finish first
		tasks.push (next) ->
			setTimeout(
				->
					assert.equal(0, tasksCompleted, 'the second task finished first as expected')
					++tasksCompleted
					next()
				500
			)
		
		# Check no tasks have run
		assert.equal(0, tasksCompleted, 'no tasks should have started yet')
		
		# Run the tasks
		tasks.async()

		# Check all tasks ran
		setTimeout(
			->
				assert.equal(tasksExpected, tasksCompleted, 'only the expected number of tasks ran')
				done()
			2000
		)

