# Requires
# none


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

class Group
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

	# What to do next?
	next: ->
		throw new Error 'Groups require a completion callback'
	
	# Construct our group
	constructor: (@next,mode) ->
		@queue = []
		@mode = mode  if mode
	
	# Next task
	nextTask: ->
		++@queueIndex
		if @queue[@queueIndex]?
			task = @queue[@queueIndex]
			task @completer()
		@
		
	# A task has completed
	complete: (err) ->
		if @exited is false
			if err
				return @exit err
			else
				++@completed
				if @completed is @total
					return @exit()
				else if @mode is 'sync'
					@nextTask()
		@
	
	# Alias for complete
	completer: ->
		return (err) => @complete(err)
	
	# The group has finished
	exit: (err=false) ->
		if @exited is false
			@exited = true
			@next?(err)
		else
			@next?(new Error 'Group has already exited')
		@
	
	# Push a set of tasks to the group
	tasks: (tasks) ->
		for task in tasks
			@push task
		@
	
	# Push a new task to the group
	push: (task) ->
		++@total
		@queue.push task
		@
	
	# Run the tasks
	run: ->
		if @mode is 'sync'
			@queueIndex = 0
			if @queue[@queueIndex]?
				task = @queue[@queueIndex]
				task @completer()
		else
			for task in @queue
				task @completer()
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

module.exports = {Group}