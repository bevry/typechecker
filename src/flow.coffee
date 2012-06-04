# Requires
# none

# =====================================
# Flow

balUtilFlow =


	# =====================================
	# Flow
	# Flow based helpers

	# Is an item a string
	toString: (obj) ->
		return Object::toString.call(obj)

	# Is an item an array
	isArray: (obj) ->
		return @toString(obj) is '[object Array]'

	# Cycle through each item in an array or object
	each: (obj,callback,context) ->
		# Prepare
		broke = false
		context or= obj

		# Handle
		if @isArray(obj)
			for item,key in obj
				if callback.call(context,item,key,obj) is false
					broke = true
					break
		else
			for own key,item of obj
				if callback.call(context,item,key,obj) is false
					broke = true
					break

		# Chain
		@

	# Flow through a series of actions on an object
	# next(err)
	flow: (opts) ->
		# Extract
		{object,action,args,tasks,next} = opts

		# Check
		unless action
			throw new Error('balUtilFlow.flow called without any action')

		# Create tasks group and cycle through it
		actions = action.split(/[,\s]+/g)
		tasks or= new balUtilFlow.Group(next)
		balUtilFlow.each actions, (action) -> tasks.push (complete) ->
			# Prepare callback
			argsClone = (args or []).slice()
			argsClone.push(complete)

			# Fire the action with the next helper
			fn = object[action]
			fn.apply(object,argsClone)

		# Fire the tasks synchronously
		tasks.sync()

		# Chain
		@


	# =====================================
	# Group
	# Easily group together asynchronmous functions and run them synchronously or asynchronously

	###
	Usage:
		# Add tasks to a queue then fire them in parallel (asynchronously)
		tasks = new Group (err) -> next err
		tasks.push (complete) -> someAsyncFunction(arg1, arg2, complete)
		tasks.push (complete) -> anotherAsyncFunction(arg1, arg2, complete)
		tasks.async()

		# Add tasks to a queue then fire them in serial (synchronously)
		tasks = new Group (err) -> next err
		tasks.push (complete) -> someAsyncFunction(arg1, arg2, complete)
		tasks.push (complete) -> anotherAsyncFunction(arg1, arg2, complete)
		tasks.sync()
	###

	Group: class
		# How many tasks do we have
		total: 0

		# How many tasks have completed?
		completed: 0

		# How many tasks are currently running?
		running: 0

		# Have we already exited?
		exited: false

		# Should we break on errors?
		breakOnError: true

		# Should we auto clear?
		autoClear: false

		# Queue
		queue: []

		# Mode
		mode: 'async'

		# Results
		lastResult: null
		results: []
		errors: []

		# What to do next?
		next: ->
			throw new Error 'Groups require a completion callback'

		# Construct our group
		constructor: (args...) ->
			@clear()
			for arg in args
				if typeof arg is 'string'
					@mode = arg
				else if typeof arg is 'function'
					@next = arg
				else if typeof arg is 'object'
					{next,mode,breakOnError,autoClear} = arg
					@next = next  if next
					@mode = mode  if mode
					@breakOnError = breakOnError  if breakOnError
					@autoClear = autoClear  if autoClear
				else
					throw new Error 'Unknown argument sent to Groups constructor'

		# Clear the queue
		clear: ->
			# Clear all our properties
			@total = 0
			@completed = 0
			@running = 0
			@exited = false
			@queue = []
			@results = []
			@errors = []
			@lastResult = null

			# Chain
			@

		# Check if we have tasks
		hasTasks: ->
			return @queue.length isnt 0

		# Check if we have completed
		hasCompleted: ->
			return @total isnt 0  and  @total is @completed

		# Check if we are currently running
		isRunning: ->
			return @running isnt 0

		# Check if we have exited
		hasExited: (value) ->
			@exited = value  if value?
			return @exited is true

		# A task has completed
		complete: (args...) ->
			# Push the result
			err = args[0] or undefined
			@lastResult = args
			@errors.push(err)  if err
			@results.push(args)

			# We are one less running task
			if @running isnt 0
				--@running

			# Check if we have already completed
			if @hasExited()
				# if so, do nothing

			# Otherwise
			else
				# If we have an error, and we are told to break on an error, then we should
				if err and @breakOnError
					@exit()

				# Otherwise complete the task successfully
				# and run the next task if we have one
				# otherwise, exit
				else
					++@completed
					if @hasTasks()
						@nextTask()
					else if @isRunning() is false and @hasCompleted()
						@exit()

			# Chain
			@

		# Alias for complete
		completer: ->
			return (args...) => @complete(args...)

		# The group has finished
		exit: (err=null) ->
			# Check if we have already exited, if so, ignore
			if @hasExited()
				# do nothing

			# Otherwise
			else
				# Fetch the results
				lastResult = @lastResult
				errors = if @errors.length isnt 0 then @errors else null
				results = @results

				# Clear, and exit with the results
				if @autoClear
					@clear()
				else
					@hasExited(true)
				@next?(errors,lastResult,results)

			# Chain
			@

		# Push a set of tasks to the group
		tasks: (tasks) ->
			# Push the tasks
			@push(task)  for task in tasks

			# Chain
			@

		# Push a new task to the group
		push: (task) ->
			# Add the task and increment the count
			++@total
			@queue.push(task)

			# Chain
			@

		# Push and run
		pushAndRun: (task) ->
			# Check if we are currently running in sync mode
			if @mode is 'sync' and @isRunning()
				# push the task for later
				@push(task)
			else
				# run the task now
				++@total
				@runTask(task)

			# Chain
			@

		# Next task
		nextTask: ->
			# Only run the next task if we have one
			if @hasTasks()
				task = @queue.shift()
				@runTask(task)

			# Chain
			@

		# Run a task
		runTask: (task) ->
			# Run it, and catch errors
			try
				++@running
				task @completer()
			catch err
				@complete(err)

			# Chain
			@

		# Run the tasks
		run: ->
			if @isRunning() is false
				@hasExited(false)
				if @hasTasks()
					if @mode is 'sync'
						@nextTask()
					else
						@nextTask()  for task in @queue
				else
					@exit()
			@

		# Async
		async: ->
			@mode = 'async'
			@run()
			@

		# Sync
		sync: ->
			@mode = 'sync'
			@run()
			@


# =====================================
# Export
# for node.js and browsers

if module? then (module.exports = balUtilFlow) else (@balUtilFlow = balUtilFlow)