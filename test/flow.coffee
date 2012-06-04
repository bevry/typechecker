# Requires
assert = require('assert')
balUtil = require(__dirname+'/../lib/balutil')


# =====================================
# Tests

wait = (delay,fn) -> setTimeout(fn,delay)

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
		firstTaskFinished = false
		secondTaskFinished = false
		finished = false

		# Create our group
		tasks = new balUtil.Group (err) ->
			assert.equal(false, finished, 'the group of tasks only finished once')
			finished = true
			assert.equal(false, err?, 'no error is present')
		tasks.total = 2

		# Make the first task finish after the second task
		wait 1000, ->
			firstTaskFinished = true
			assert.equal(true, secondTaskFinished, 'the first task ran second as expected')
			tasks.complete()

		# Make the second task finish before the first task
		wait 500, ->
			secondTaskFinished = true
			assert.equal(false, firstTaskFinished, 'the second task ran first as expected')
			tasks.complete()

		# Check no tasks have run
		assert.equal(0, tasks.completed, 'no tasks should have started yet')

		# Check all tasks ran
		wait 2000, ->
			assert.equal(2, tasks.completed, 'only the expected number of tasks ran')
			assert.equal(false, tasks.isRunning(), 'isRunning() returned false')
			assert.equal(true, tasks.hasCompleted(), 'hasCompleted() returned true')
			assert.equal(true, tasks.hasExited(), 'hasExited() returned true')
			done()


	it 'should work when run synchronously', (done) ->
		# Prepare
		@timeout(2200)
		firstTaskRun = false
		secondTaskRun = false
		firstTaskFinished = false
		secondTaskFinished = false
		finished = false

		# Create our group
		tasks = new balUtil.Group (err) ->
			assert.equal(false, finished, 'the group of tasks only finished once')
			finished = true
			assert.equal(false, err?, 'no error is present')

		# Make the first task take longer than the second task, but as we run synchronously, it should still finish first
		tasks.push (complete) ->
			firstTaskRun = true
			assert.equal(false, secondTaskRun, 'the first task ran first as expected')
			wait 1000, ->
				firstTaskFinished = true
				assert.equal(false, secondTaskFinished, 'the first task completed first as expected')
				complete()

		# Make the second task take shorter than the first task, but as we run synchronously, it should still finish second
		tasks.push (complete) ->
			secondTaskRun = true
			assert.equal(true, firstTaskRun, 'the second task ran second as expected')
			wait 500, ->
				secondTaskFinished = true
				assert.equal(true, firstTaskFinished, 'the second task completed second as expected')
				complete()

		# Check no tasks have run
		assert.equal(0, tasks.completed, 'no tasks should have started yet')

		# Run the tasks
		tasks.sync()
		assert.equal(true, tasks.isRunning(), 'isRunning() returned true')

		# Check all tasks ran
		wait 2000, ->
			assert.equal(2, tasks.completed, 'only the expected number of tasks ran')
			assert.equal(false, tasks.isRunning(), 'isRunning() returned false')
			assert.equal(true, tasks.hasCompleted(), 'hasCompleted() returned true')
			assert.equal(true, tasks.hasExited(), 'hasExited() returned true')
			done()


	it 'should work when run asynchronously', (done) ->
		# Prepare
		@timeout(2200)
		firstTaskRun = false
		secondTaskRun = false
		firstTaskFinished = false
		secondTaskFinished = false
		finished = false

		# Create our group
		tasks = new balUtil.Group (err) ->
			assert.equal(false, finished, 'the group of tasks only finished once')
			finished = true
			assert.equal(false, err?, 'no error is present')

		# Make the first task take longer than the second task, and as we run asynchronously, it should finish last
		tasks.push (complete) ->
			firstTaskRun = true
			assert.equal(false, secondTaskRun, 'the first task ran first as expected')
			wait 1000, ->
				firstTaskFinished = true
				assert.equal(true, secondTaskFinished, 'the first task completed second as expected')
				complete()

		# Make the second task take shorter than the first task, and as we run asynchronously, it should finish first
		tasks.push (complete) ->
			secondTaskRun = true
			assert.equal(true, firstTaskRun, 'the second task ran second as expected')
			wait 500, ->
				secondTaskFinished = true
				assert.equal(false, firstTaskFinished, 'the second task completed first as expected')
				complete()

		# Check no tasks have run
		assert.equal(0, tasks.completed, 'no tasks should have started yet')

		# Run the tasks
		tasks.async()
		assert.equal(true, tasks.isRunning(), 'isRunning() returned true')

		# Check all tasks ran
		wait 2000, ->
			assert.equal(2, tasks.completed, 'only the expected number of tasks ran')
			assert.equal(false, tasks.isRunning(), 'isRunning() returned false')
			assert.equal(true, tasks.hasCompleted(), 'hasCompleted() returned true')
			assert.equal(true, tasks.hasExited(), 'hasExited() returned true')
			done()



	it 'should handle errors correctly', (done) ->
		# Prepare
		@timeout(2200)
		firstTaskRun = false
		secondTaskRun = false
		firstTaskFinished = false
		secondTaskFinished = false
		finished = false

		# Create our group
		tasks = new balUtil.Group (err) ->
			assert.equal(false, finished, 'the group of tasks only finished once')
			finished = true
			assert.equal(true, err?, 'an error is present')

		# Make the first task take longer than the second task, but as we run synchronously, it should still finish first
		tasks.push (complete) ->
			firstTaskRun = true
			assert.equal(false, secondTaskRun, 'the first task ran first as expected')
			wait 1000, ->
				firstTaskFinished = true
				assert.equal(false, secondTaskFinished, 'the first task completed first as expected')
				complete()

		# Make the second task take shorter than the first task, but as we run synchronously, it should still finish second
		tasks.push (complete) ->
			secondTaskRun = true
			assert.equal(true, firstTaskRun, 'the second task ran second as expected')
			wait 500, ->
				secondTaskFinished = true
				assert.equal(true, firstTaskFinished, 'the second task completed second as expected')
				complete(new Error('deliberate error'))

		# Check no tasks have run
		assert.equal(0, tasks.completed, 'no tasks should have started yet')

		# Run the tasks
		tasks.sync()
		assert.equal(true, tasks.isRunning(), 'isRunning() returned true')

		# Check all tasks ran
		wait 2000, ->
			assert.equal(1, tasks.completed, 'only the expected number of tasks ran')
			assert.equal(false, tasks.isRunning(), 'isRunning() returned false')
			assert.equal(false, tasks.hasCompleted(), 'hasCompleted() returned true')
			assert.equal(true, tasks.hasExited(), 'hasExited() returned true')
			done()


	it 'should push and run synchronous tasks correctly', (done) ->
		# Prepare
		@timeout(5000)
		firstTaskRun = false
		secondTaskRun = false
		firstTaskFinished = false
		secondTaskFinished = false
		finished = false

		# Create our group
		tasks = new balUtil.Group 'sync', (err) ->
			assert.equal(false, finished, 'the group of tasks only finished once')
			finished = true
			assert.equal(false, err?, 'no error is present')
		assert.equal('sync', tasks.mode, 'mode was correctly set to sync')

		# Make the first task take longer than the second task, but as we run synchronously, it should still finish first
		tasks.pushAndRun (complete) ->
			firstTaskRun = true
			assert.equal(false, secondTaskRun, 'the first task ran first as expected')
			wait 1000, ->
				firstTaskFinished = true
				assert.equal(false, secondTaskFinished, 'the first task completed first as expected')
				complete()

		# We're now running, so test that
		assert.equal(true, tasks.isRunning(), 'isRunning() returned true')

		# Make the second task take shorter than the first task, but as we run synchronously, it should still finish second
		tasks.pushAndRun (complete) ->
			secondTaskRun = true
			assert.equal(true, firstTaskRun, 'the second task ran second as expected')
			wait 500, ->
				secondTaskFinished = true
				assert.equal(true, firstTaskFinished, 'the second task completed second as expected')
				complete()

		# Check all tasks ran
		wait 4000, ->
			assert.equal(2, tasks.completed, 'only the expected number of tasks ran')
			assert.equal(false, tasks.isRunning(), 'isRunning() returned false')
			assert.equal(true, tasks.hasCompleted(), 'hasCompleted() returned true')
			assert.equal(true, tasks.hasExited(), 'hasExited() returned true')
			done()



	it 'should push and run asynchronous tasks correctly (queued)', (done) ->
		# Prepare
		@timeout(5000)
		firstTaskRun = false
		secondTaskRun = false
		firstTaskFinished = false
		secondTaskFinished = false
		finished = false

		# Create our group
		tasks = new balUtil.Group 'async', (err) ->
			assert.equal(false, finished, 'the group of tasks only finished once')
			finished = true
			assert.equal(false, err?, 'no error is present')
		assert.equal('async', tasks.mode, 'mode was correctly set to async')

		# Make the first task take longer than the second task, but as we run synchronously, it should still finish first
		tasks.pushAndRun (complete) ->
			firstTaskRun = true
			assert.equal(false, secondTaskRun, 'the first task ran first as expected')
			wait 1000, ->
				firstTaskFinished = true
				assert.equal(true, secondTaskFinished, 'the first task completed second as expected')
				complete()

		# We're now running, so test that
		assert.equal(true, tasks.isRunning(), 'isRunning() returned true')

		# Make the second task take shorter than the first task, but as we run synchronously, it should still finish second
		tasks.pushAndRun (complete) ->
			secondTaskRun = true
			assert.equal(true, firstTaskRun, 'the second task ran second as expected')
			wait 500, ->
				secondTaskFinished = true
				assert.equal(false, firstTaskFinished, 'the second task completed first as expected')
				complete()

		# Check all tasks ran
		wait 4000, ->
			assert.equal(2, tasks.completed, 'only the expected number of tasks ran')
			assert.equal(false, tasks.isRunning(), 'isRunning() returned false')
			assert.equal(true, tasks.hasCompleted(), 'hasCompleted() returned true')
			assert.equal(true, tasks.hasExited(), 'hasExited() returned true')
			done()


	it 'should push and run synchronous tasks correctly (multiple times)', (done) ->
		# Prepare
		@timeout(2200)
		finished = 0

		# Create our group
		tasks = new balUtil.Group 'sync', {autoClear: true}, (err) ->
			++finished
			assert.equal(false, err?, 'no error is present')
		assert.equal('sync', tasks.mode, 'mode was correctly set to sync')
		assert.equal(true, tasks.autoClear, 'autoClear was correctly set to true')

		# Fire the first task right away
		tasks.pushAndRun (complete) -> complete()

		# Fire the second task after a while
		wait 500, ->
			tasks.pushAndRun (complete) -> wait 500, -> complete()
			assert.equal(true, tasks.isRunning(), 'isRunning() returned true')

		# Check all tasks ran
		wait 2000, ->
			assert.equal(2, finished, 'it exited the correct number of times')
			assert.equal(false, tasks.isRunning(), 'isRunning() returned false')
			assert.equal(false, tasks.hasCompleted(), 'hasCompleted() returned false')
			assert.equal(false, tasks.hasExited(), 'hasExited() returned false')
			done()
