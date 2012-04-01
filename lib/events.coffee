# Require
EventEmitter = require('events').EventEmitter
balUtilFlow = require("#{__dirname}/flow.coffee")
debug = false


# =====================================
# Event & EventSystem
# Extends the standard EventEmitter with support for:
# - blocking events
# - start and finish events
# - cycling synchronous events

# Event
class Event
	# The name of the event
	name: null
	# Is the event currently locked?
	locked: false
	# Has the event finished running?
	finished: false
	# Apply our name on construction
	constructor: ({@name}) ->

# EventSystem
class EventSystem extends EventEmitter
	# Event store
	# initialised in our event function to prevent javascript reference problems
	_eventSystemEvents: null
	
	# Fetch the event object for the event
	event: (eventName) ->
		# Prepare
		@_eventSystemEvents or= {}
		# Return the fetched event, create it if it doesn't exist already
		@_eventSystemEvents[eventName] or= new Event(eventName)
	
	# Lock the event
	# next(err)
	lock: (eventName, next) ->
		# Grab the event
		event = @event eventName
		# Grab a lock on the event
		if event.locked is false
			# Place the lock
			event.locked = true
			# Trigger our event
			# then fire our callback
			try
				@emit eventName+':locked'
			catch err
				next?(err)
				return @
			finally
				next?()
		else
			# Wait until the current task has finished
			@onceUnlocked eventName, (err) =>
				return next?(err)  if err
				# Then try again
				@lock eventName, next
		
		# Chain
		@
	
	# Unlock the event
	# next(err)
	unlock: (eventName, next) ->
		# Grab the event
		event = @event eventName
		# Release the lock
		event.locked = false
		# Trigger our event
		# then fire our callback
		try
			@emit eventName+':unlocked'
		catch err
			next?(err)
			return @
		finally
			next?()
		# Chain
		@
	
	# Start our event
	# 1. Performs a lock
	# 2. Sets event's finished flag to false
	# 3. Fires callback
	# next(err)
	start: (eventName, next) ->
		# Grab a locak
		@lock eventName, (err) =>
			# Error?
			return next?(err)  if err
			# Grab the event
			event = @event eventName
			# Set as started
			event.finished = false
			# Trigger our event
			# then fire our callback
			try
				@emit eventName+':started'
			catch err
				next?(err)
				return @
			finally
				next?()
		# Chain
		@
	
	# Finish, alias for finished
	finish: (args...) ->
		@finished.apply(@,args)
	
	# Finished our event
	# 1. Sets event's finished flag to true
	# 2. Unlocks the event
	# 3. Fires callback
	# next(err)
	finished: (eventName, next) ->
		# Grab the event
		event = @event eventName
		# Set as finished
		event.finished = true
		# Unlock
		@unlock eventName, (err) =>
			# Error?
			return next?(err)  if err
			# Trigger our event
			# then fire our callback
			try
				@emit eventName+':finished'
			catch err
				next?(err)
				return @
			finally
				next?()
		# Chain
		@
	
	# Run one time once an event has unlocked
	# next(err)
	onceUnlocked: (eventName, next) ->
		# Log
		console.log "onceUnlocked #{eventName}"  if debug
		# Grab the event
		event = @event eventName
		# Check lock status
		if event.locked
			# Wait until our event has unlocked to fire the callback
			@once eventName+':unlocked', next
		else
			# Fire our callback now
			next?()
		# Chain
		@
	
	# Run one time once an event has finished
	# next(err)
	onceFinished: (eventName, next) ->
		# Grab the event
		event = @event eventName
		# Check finish status
		if event.finished
			# Fire our callback now
			next?()
		else
			# Wait until our event has finished to fire the callback
			@once eventName+':finished', next
		# Chain
		@
	
	# Run every time an event has finished
	# next(err)
	whenFinished: (eventName, next) ->
		# Grab the event
		event = @event eventName
		# Check finish status
		if event.finished
			# Fire our callback now
			next?()
		# Everytime our even has finished, fire the callback
		@on eventName+':finished', next
		# Chain
		@
	
	# When, alias for on
	when: (args...) ->
		@on.apply(@,args)

	# Block an event from running
	# next(err)
	block: (eventNames, next) ->
		# Ensure array
		if (eventNames instanceof Array) is false
			if typeof eventNames is 'string'
				eventNames = eventNames.split /[,\s]+/g
			else
				return next? new Error 'Unknown eventNames type'
		total = eventNames.length
		done = 0
		# Block these events
		for eventName in eventNames
			@lock eventName, (err) ->
				# Error?
				if err
					done = total
					return next?(err)
				# Increment
				done++
				if done is total
					next?()
		# Chain
		@

	# Unblock an event from running
	# next(err)
	unblock: (eventNames, next) ->
		# Ensure array
		if (eventNames instanceof Array) is false
			if typeof eventNames is 'string'
				eventNames = eventNames.split /[,\s]+/g
			else
				return next? new Error 'Unknown eventNames type'
		total = eventNames.length
		done = 0
		# Block these events
		for eventName in eventNames
			@unlock eventName, (err) ->
				# Error?
				if err
					done = total
					return next?(err)
				# Increment
				done++
				if done is total
					next?()
		# Chain
		@
	
	# Emit a group of listeners asynchronously
	# next(err,result,results)
	emitAsync: (eventName,data,next) ->
		# Get listeners
		listeners = @listeners(eventName)
		# Prepare tasks
		tasks = new balUtilFlow.Group(next)
		# Add the tasks for the listeners
		balUtilFlow.each listeners, (listener) ->
			tasks.push (complete) ->
				listener(data,complete)
		# Trigger asynchronously
		tasks.async()
		# Chain
		@

	# Emit a group of listeners synchronously
	# next(err,result,results)
	emitSync: (eventName,data,next) ->
		# Get listeners
		listeners = @listeners(eventName)
		# Prepare tasks
		tasks = new balUtilFlow.Group(next)
		# Add the tasks for the listeners
		balUtilFlow.each listeners, (listener) ->
			tasks.push (complete) ->
				listener(data,complete)
		# Trigger synchronously
		tasks.sync()
		# Chain
		@


# =====================================
# Export

module.exports = {Event,EventSystem}