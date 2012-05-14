# Requires
# none

# =====================================
# Flow

balUtilFlow =


	# =====================================
	# Flow
	# Flow based helpers

	toString: (obj) ->
		return Object::toString.call(obj)

	isArray: (obj) ->
		return @toString(obj) is '[object Array]'

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


	# =====================================
	# Group
	# Easily group together asynchronmous functions and run them synchronously or asynchronously

	###
	Usage:

		# Fire tasks as we go
		tasks = new Group (err) -> next err
		tasks.total = 2
		someAsyncFunction arg1, arg2, tasks.completer()
		anotherAsyncFunction arg1, arg2, (err) ->
			tasks.complete err

		# Add tasks to a queue then fire them together asynchronously
		tasks = new Group (err) -> next err
		tasks.push ((arg1,arg2) -> someAsyncFunction arg1, arg2, tasks.completer())(arg1,arg2)
		tasks.push ((arg1,arg2) -> anotherAsyncFunction arg1, arg2, tasks.completer())(arg1,arg2)
		tasks.run()

		# Add tasks to a queue then fire them together synchronously
		tasks = new Group (err) -> next err
		tasks.push ((arg1,arg2) -> someAsyncFunction arg1, arg2, tasks.completer())(arg1,arg2)
		tasks.push ((arg1,arg2) -> anotherAsyncFunction arg1, arg2, tasks.completer())(arg1,arg2)
		tasks.run()
	###

	Group: class
		# How many tasks do we have
		total: 0

		# How many tasks have completed?
		completed: 0

		# Have we already exited?
		exited: false

		# Queue
		queue: []
		queueIndex: 0

		# Mode
		mode: 'async'

		# Results
		lastResult: null
		results: []

		# What to do next?
		next: ->
			throw new Error 'Groups require a completion callback'

		# Construct our group
		constructor: (@next,mode) ->
			@clear()
			@mode = mode  if mode

		# Next task
		nextTask: ->
			++@queueIndex
			if @queue[@queueIndex]?
				task = @queue[@queueIndex]
				task @completer()
			@

		# Check if we have completed
		hasCompleted: ->
			return @total is @completed

		# Clear the queue
		clear: ->
			@queue = []
			@queueIndex = 0
			@results = []
			@lastResult = null

		# A task has completed
		complete: (args...) ->
			err = args[0] or undefined
			@lastResult = args
			@results.push(args)
			if @exited is false
				if err
					return @exit err
				else
					++@completed
					if @hasCompleted()
						return @exit()
					else if @mode is 'sync'
						@nextTask()
			@

		# Alias for complete
		completer: ->
			return (args...) => @complete(args...)

		# The group has finished
		exit: (err=false) ->
			if @exited is false
				@exited = true
				lastResult = @lastResult
				results = @results
				@clear()
				@next?(err,lastResult,results)
			else
				err = new Error('Group has already exited')
				lastResult = @lastResult
				results = @results
				@clear()
				@next?(err,lastResult,results)
			@

		# Push a set of tasks to the group
		tasks: (tasks) ->
			for task in tasks
				@push(task)
			@

		# Push a new task to the group
		push: (task) ->
			++@total
			@exited = false
			@queue.push(task)
			@

		# Push and run
		pushAndRun: (task) ->
			@push(task)
			task @completer()
			@

		# Run the tasks
		run: ->
			@exited = false
			if @mode is 'sync'
				@queueIndex = 0
				if @queue[@queueIndex]?
					task = @queue[@queueIndex]
					try
						task @completer()
					catch err
						@complete(err)
				else
					@exit()  # nothing to do
			else
				unless @queue.length
					@exit()  # nothing to do
				else
					for task in @queue
						try
							task @completer()
						catch err
							@complete(err)
			@

		# Async
		async: (args...) ->
			@mode = 'async'
			@run(args...)
			@

		# Sync
		sync: (args...) ->
			@mode = 'sync'
			@run(args...)
			@


# =====================================
# Export
# for node.js and browsers

if module? then (module.exports = balUtilFlow) else (@balUtilFlow = balUtilFlow)