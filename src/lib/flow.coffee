# Requires
balUtilTypes = require?(__dirname+'/types') or @balUtilTypes

# =====================================
# Flow

balUtilFlow =


	# =====================================
	# Flow
	# Flow based helpers

	# Wait a certain amount of milliseconds before firing the function
	wait: (delay,fn) ->
		setTimeout(fn,delay)

	# Extract the correct options and completion callback from the passed arguments
	extractOptsAndCallback: (opts,next) ->
		if balUtilTypes.isFunction(opts) and next? is false
			next = opts
			opts = {}
		else
			opts or= {}
		next or= opts.next or null
		return [opts,next]

	# Fire a function with an optional callback
	# The last passed argument in args is considered the completion callback
	# It is optional, as in, the method we call can either use it (async)
	# or not (sync). The completion callback expects two arguments (err,result)
	# if sync, we expect an error object (err) or something else returned (result)
	fireWithOptionalCallback: (method,args,context) ->
		# Prepare
		args or= []
		callback = args[args.length-1]
		context or= null
		result = null

		# We have the callback
		# assume it is async
		if method.length is args.length
			# Fire the function
			try
				result = method.apply(context,args)
			catch caughtError
				callback(caughtError)

		# We don't have the callback
		# assume it is sync
		else
			# Prepare
			err = null

			# Fire the function
			try
				result = method.apply(context,args)
				err = result  if balUtilTypes.isError(result)
			catch caughtError
				err = caughtError

			# Fire the callback
			callback(err,result)

		# Return the result
		return result

	# Extend
	extend: (target,objs...) ->
		target or= {}
		for obj in objs
			obj or= {}
			for own key,value of obj
				target[key] = value
		return target

	# Clone
	clone: (source) ->
		target = {}
		args.unshift(target)
		balUtilFlow.extend(target,source)
		return target

	# Return a dereferenced copy of the object
	# Will not keep functions
	dereference: (source) ->
		target = JSON.parse(JSON.stringify(source))
		return target

	# Cycle through each item in an array or object
	each: (obj,callback,context) ->
		# Prepare
		broke = false
		context or= obj

		# Handle
		if balUtilTypes.isArray(obj)
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

balUtilFlow.Group = class
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
			if balUtilTypes.isString(arg)
				@mode = arg
			else if balUtilTypes.isFunction(arg)
				@next = arg
			else if balUtilTypes.isObject(arg)
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

	# Log an error
	logError: (err) ->
		# Only push the error if we haven't already added it
		if @errors[@errors.length-1] isnt err
			@errors.push(err)
		# Chain
		@

	# A task has completed
	complete: (args...) ->
		# Push the result
		err = args[0] or undefined
		@lastResult = args
		@logError(err)  if err
		@results.push(args)

		# We are one less running task
		if @running isnt 0
			--@running

		# Check if we have already completed
		if @hasExited()
			# do nothing

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
		# Push the error if we were passed one
		@logError(err)  if err

		# Check if we have already exited, if so, ignore
		if @hasExited()
			# do nothing

		# Otherwise
		else
			# Fetch the results
			lastResult = @lastResult
			results = @results

			# If have multiple errors, return an array
			# If we have one error, return that error
			# If we have no errors, retur null
			if @errors.length is 0
				errors = null
			else if @errors.length is 1
				errors = @errors[0]
			else
				errors = @errors

			# Clear, and exit with the results
			if @autoClear
				@clear()
			else
				@hasExited(true)
			@next(errors,lastResult,results)

		# Chain
		@

	# Push a set of tasks to the group
	tasks: (tasks) ->
		# Push the tasks
		@push(task)  for task in tasks

		# Chain
		@

	# Push a new task to the group
	push: (args...) ->
		# Add the task and increment the count
		++@total

		# Queue
		@queue.push(args)

		# Chain
		@

	# Push and run
	pushAndRun: (args...) ->
		# Check if we are currently running in sync mode
		if @mode is 'sync' and @isRunning()
			# push the task for later
			@push(args...)
		else
			# run the task now
			++@total
			@runTask(args)

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
		# Prepare
		me = @

		# Run it, and catch errors
		try
			run = ->
				++me.running
				complete = me.completer()
				if balUtilTypes.isArray(task)
					if task.length is 2
						_context = task[0]
						_task = task[1]
					else if task.length is 1
						_task = task[0]
						_context = null
					else
						throw new Error('balUtilFlow.Group an invalid task was pushed')
				else
					_task = task
				balUtilFlow.fireWithOptionalCallback(_task,[complete],_context)

			# Fire with an immediate timeout for async loads, and every hundredth sync task, except for the first
			# otherwise if we are under a stressful load node will crash with
			# a segemantion fault / maximum call stack exceeded / range error
			if @completed isnt 0 and (@mode is 'async' or (@completed % 100) is 0)
				setTimeout(run,0)
			# Otherwise run the task right away
			else
				run()
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
# Block
# Block together a series of tasks

# Block
balUtilFlow.Block = class extends balUtilFlow.Group

	# Events
	blockBefore: (block) ->
	blockAfter: (block,err) ->
	blockTaskBefore: (block,task,err) ->
	blockTaskAfter: (block,task,err) ->

	# Create a new block and run it
	# fn(block.block, block.task, block.exit)
	# complete(err)
	constructor: (opts) ->
		# Prepare
		block = @
		{name, fn, parentBlock, complete} = opts

		# Apply options
		block.blockName = name
		block.parentBlock = parentBlock  if parentBlock?
		block.mode = 'sync'
		block.fn = fn

		# Create group
		super (err) ->
			block.blockAfter(block,err)
			complete?(err)

		# Event
		block.blockBefore(block)

		# If we have an fn
		if block.fn?
			# If our fn has a completion callback
			# then set the total tasks to infinity
			# so we wait for the competion callback instead of completeling automatically
			if block.fn.length is 3
				block.total = Infinity

			# Fire the init function
			try
				block.fn(
					# Create sub block
					(name,fn) -> block.block(name,fn)
					# Create sub task
					(name,fn) -> block.task(name,fn)
					# Complete
					(err) -> block.exit(err)
				)

				# If our fn completion callback is synchronous
				# then fire our tasks right away
				if block.fn.length isnt 3
					block.run()
			catch err
				block.exit(err)
		else
			# We don't have an fn
			# So lets set our total tasks to infinity
			block.total = Infinity

		# Chain
		@

	# Create a sub block
	# fn(subBlock, subBlock.task, subBlock.exit)
	block: (name,fn) ->
		# Push the creation of our subBlock to our block's queue
		block = @
		pushBlock = (fn) ->
			if block.total is Infinity
				block.pushAndRun(fn)
			else
				block.push(fn)
		pushBlock (complete) ->
			subBlock = block.createSubBlock({name,fn,complete})
		@

	# Create a sub block
	createSubBlock: (opts) ->
		opts.parentBlock = @
		new balUtilFlow.Block(opts)

	# Create a task for our current block
	# fn(complete)
	task: (name,fn) ->
		# Prepare
		block = @
		pushTask = (fn) ->
			if block.total is Infinity
				block.pushAndRun(fn)
			else
				block.push(fn)

		# Push the task to the correct place
		pushTask (complete) ->
			# Prepare
			preComplete = (err) ->
				block.blockTaskAfter(block,name,err)
				complete(err)

			# Event
			block.blockTaskBefore(block,name)

			# Fire the task, treating the callback as optional
			balUtilFlow.fireWithOptionalCallback(fn,[preComplete])

		# Chain
		@

# =====================================
# Runner
# Run a series of tasks as a block

balUtilFlow.Runner = class
	runnerBlock: null
	constructor: ->
		@runnerBlock ?= new balUtilFlow.Block()
	getRunnerBlock: ->
		@runnerBlock
	block: (args...) ->
		@getRunnerBlock().block(args...)
	task: (args...) ->
		@getRunnerBlock().task(args...)


# =====================================
# Export
# for node.js and browsers

if module? then (module.exports = balUtilFlow) else (@balUtilFlow = balUtilFlow)