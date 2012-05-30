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
			console.log(opts);
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

		# Check if we have exited
		hasExited: (value) ->
			@exited = value  if value?
			return @exited is true

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
			if @hasExited() is false
				if err
					return @exit(err)
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
		exit: (err=null) ->
			if @hasExited() is false
				@hasExited(true)
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
			@hasExited(false)
			@queue.push(task)
			@

		# Push and run
		pushAndRun: (task) ->
			@push(task)
			task @completer()
			@

		# Run the tasks
		run: ->
			@hasExited(false)
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