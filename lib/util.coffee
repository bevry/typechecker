# Util
# A series of utility functions to help speed up node.js development

# Requirements
fs = require('fs')
EventEmitter = require('events').EventEmitter
request = null
child_process = null
debug = false

# =====================================

# Types
# Provides higher level typeof functionality
type =
	# Get the type
	get: (value) ->
		# Prepare
		result = 'object'

		# Cycle
		for type in ['array','regex','function','boolean','number','string','null','undefined']
			if @[type] value
				result = type
				break
		
		# Return
		return result

	# Checks to see if a value is an object
	object: (value) ->
		return @get(value) is 'object'
		
	# Checks to see if a value is a function
	function: (value) ->
		return value instanceof Function

	# Checks to see if a value is an regex
	regex: (value) ->
		return value instanceof RegExp

	# Checks to see if a value is an array
	array: (value) ->
		return value instanceof Array

	# Checks to see if a valule is a boolean
	boolean: (value) ->
		return typeof value is 'boolean'
		#return value.toString() in ['false','true']

	# Checks to see if a valule is a number
	number: (value) ->
		return value? and typeof value.toPrecision isnt 'undefined'

	# Checks to see if a value is a string
	string: (value) ->
		return value? and typeof value.charAt isnt 'undefined'

	# Checks to see if a value is null
	'null': (value) ->
		return value is null

	# Checks to see if a value is undefined
	'undefined': (value) ->
		return typeof value is 'undefined'
	
	# Checks to see if a value is empty
	empty: (value) ->
		return value?


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
	
	cycle: (eventName, data, next) ->
		# Get listeners
		listeners = @listeners(eventName)
		# Prepare tasks
		tasks = new util.Group (err) ->
			next?(err)
		tasks.total = listeners.length
		# Cycle through
		for listener in listeners
			listener data, tasks.completer()
		# Chain
		@


# =====================================

# Group
# Easily group together asynchronmous functions and run them synchronously or asynchronously
#
# Usage:
#
#	# Fire tasks as we go
#	tasks = new util.Group (err) -> next err
#   tasks.total = 2
#   someAsyncFunction arg1, arg2, tasks.completer()
#   anotherAsyncFunction arg1, arg2, (err) ->
#		tasks.complete err
#
#	# Add tasks to a queue then fire them together asynchronously
#	tasks = new util.Group (err) -> next err
#   tasks.push ((arg1,arg2) -> someAsyncFunction arg1, arg2, tasks.completer())(arg1,arg2)
#   tasks.push ((arg1,arg2) -> anotherAsyncFunction arg1, arg2, tasks.completer())(arg1,arg2)
#   tasks.run()
#
#	# Add tasks to a queue then fire them together synchronously
#	tasks = new util.Group (err) -> next err
#   tasks.push ((arg1,arg2) -> someAsyncFunction arg1, arg2, tasks.completer())(arg1,arg2)
#   tasks.push ((arg1,arg2) -> anotherAsyncFunction arg1, arg2, tasks.completer())(arg1,arg2)
#   tasks.run()
#
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
# Utilility Container

# Contains everything that we will export
util =

	# =================================
	# Events

	# Event
	Event: Event

	# EventSystem
	EventSystem: EventSystem


	# =================================
	# Groups

	# Group
	Group: Group


	# =================================
	# Types

	# Type
	type: type


	# =================================
	# Exec

	# Runs multiple commands at the same time
	# And fires the callback once they have all completed
	# callbac(err,args...) where args are the result of the exec
	exec: (commands,options,callback) ->
		# Requires
		child_process = require('child_process')  unless child_process
		
		# Sync
		mode = options.mode or null
		results = []

		# Make sure we send back the arguments
		tasks = new util.Group ->
			if mode is 'single'
				callback.apply(callback,results[0])
			else
				callback.apply(callback,[results])
		
		# Make sure we send back the arguments
		createHandler = (command) ->
			return -> child_process.exec command, options, (args...) ->
				err = args[0] or null
				
				# Push args to result list
				results.push args

				# Complete the task
				tasks.complete(err)
		
		# Prepare tasks
		if commands instanceof Array
			mode or= 'multiple'
		else
			mode or= 'single'
			commands = [commands]
		
		# Add tasks
		for command in commands
			tasks.push createHandler command

		# Run the tasks synchronously
		tasks.sync()

		# Chain
		@


	# =================================
	# Paths

	# Copy a file
	# next(err)
	cp: (src,dst,next) ->
		fs.readFile src, 'binary', (err,data) ->
			# Error
			if err
				console.log 'bal-util.cp: cp failed on:',src
				return next?(err)
			# Success
			fs.writeFile dst, data, 'binary', (err) ->
				# Forward
				if err
					console.log 'bal-util.cp: writeFile failed on:',dst
				return next?(err)
		# Chain
		@
	

	# Get the parent path
	getParentPathSync: (p) ->
		parentPath = p.replace /[\/\\][^\/\\]+$/, ''
		return parentPath
	

	# Ensure path exists
	# next(err)
	ensurePath: (p,next) ->
		path = require('path')
		p = p.replace /[\/\\]$/, ''
		path.exists p, (exists) ->
			# Error 
			return next?()  if exists
			# Success
			parentPath = util.getParentPathSync p
			util.ensurePath parentPath, (err) ->
				# Error
				if err
					console.log 'bal-util.ensurePath: failed to ensure the path:',parentPath
					return next?(err)
				# Success
				fs.mkdir p, 0700, (err) ->
					path.exists p, (exists) ->
						# Error
						if not exists
							console.log 'bal-util.ensurePath: failed to create the directory:',p
							return next?(new Error 'Failed to create the directory '+p)
						# Success
						next?()
		# Chain
		@
	

	# Prefix path
	prefixPathSync: (path,parentPath) ->
		path = path.replace /[\/\\]$/, ''
		if /^([a-zA-Z]\:|\/)/.test(path) is false
			path = parentPath + '/' + path
		return path
	

	# Is it a directory?
	# next(err,isDirectory)
	isDirectory: (fileFullPath,next) ->
		# Stat
		fs.stat fileFullPath, (err,fileStat) ->
			# Error
			if err
				console.log 'bal-util.isDirectory: stat failed on:',fileFullPath
				return next?(err)
			# Success
			return next?(null, fileStat.isDirectory())
		
		# Chain
		@
	
	
	# Generate a slug for a file
	generateSlugSync: (fileFullPath) ->
		# Slugify
		result = fileFullPath.replace(/[^a-zA-Z0-9]/g,'-').replace(/^-/,'').replace(/-+/,'-')

		# Return
		return result


	# Recursively scan a directory, file, or series of files
	scan: (files,fileAction,dirAction,next) ->
		# Actions
		actions =
			directory: =>
				@scandir(
					# Directory
					files
					# File Action
					fileAction
					# Dir Action
					dirAction
					# Complete Action
					next
				)
			
			files: =>
				# Queue
				tasks = new util.Group next
				tasks.total += files.length
			
				# Array
				for file in files
					@scan fileFullPath, fileAction, dirAction, tasks.completer()
				
				# Done
				return true
		
		# String
		if typeof files.charAt isnt 'undefined'
			util.isDirectory (err,isDirectory) ->
				# Error
				if err
					return next?(err)
				
				# Directory
				else if isDirectory
					actions.directory()
				
				# File
				else
					files = [file]
					actions.files()
		
		# Array
		else if files instanceof Array
			actions.files()
		
		# Unsupported
		else
			next?(new Error 'bal-util.scandir: unsupported files type:', typeof files, files)

		# Chain
		@
	

	# Scan a directory into a tree
	# next(err,tree)
	scantree: (dirPath,next) ->
		# Handle
		util.scandir(
			path: dirPath
			readFiles: true
			next: (err,list,tree) ->
				next?(err,tree)
		)

		# Chain
		@


	# Recursively scan a directory
	# fileAction(fileFullPath,fileRelativePath,next(err,skip)) or false
	# dirAction(fileFullPath,fileRelativePath,next(err,skip)) or false
	# next(err,list,tree)
	scandir: (args...) ->
		# Prepare
		if args.length is 1
			{path,parentPath,fileAction,dirAction,next,relativePath,readFiles} = args[0]
		else if args.length >= 4
			[parentPath,fileAction,dirAction,next] = args
		else
			err = new Error('bal-util.scandir: unknown arguments')
			if next
				return next?(err)
			else
				throw err
			
		
		# Prepare defaults
		readFiles or= false

		# Check needed
		if !parentPath and path
			parentPath = path
		if !parentPath
			err = new Error('bal-util.scandir: parentPath is needed')
			if next
				return next?(err)
			else
				throw err

		# Return
		list = {}
		tree = {}

		# Group
		tasks = new @Group (err) ->
			next?(err, list, tree)
		
		# Cycle
		fs.readdir parentPath, (err,files) ->
			# Check
			if tasks.exited
				return

			# Error
			else if err
				console.log 'bal-util.scandir: readdir has failed on:', parentPath
				return tasks.exit(err)
			
			# Empty?
			else if !files.length
				return tasks.exit()
			
			# Cycle
			else files.forEach (file) ->
				# Prepare
				++tasks.total
				fileFullPath = parentPath+'/'+file
				fileRelativePath = (if relativePath then relativePath+'/' else '')+file

				# IsDirectory
				util.isDirectory fileFullPath, (err,isDirectory) ->
					# Check
					if tasks.exited
						return
					
					# Error
					else if err
						console.log 'bal-util.scandir: isDirectory has failed on:', fileFullPath
						return tasks.exit(err)
					
					# Directory
					else if isDirectory
						# Prepare
						complete = (err,skip,subtreeCallback) ->
							# Error
							return tasks.exit(err)  if err
				
							# Exited
							return tasks.exit()  if tasks.exited

							# Handle
							if skip isnt true
								# Append
								list[fileRelativePath] = 'dir'
								tree[file] = {}

								# Recurse
								return util.scandir(
									# Path
									path: fileFullPath
									# File
									fileAction: fileAction
									# Dir
									dirAction: dirAction
									# Completed
									next: (err,_list,_tree) ->
										# Merge in children of the parent directory
										tree[file] = _tree
										for own filePath, fileType of _list
											list[filePath] = fileType

										# Exited
										if tasks.exited
											return tasks.exit()
										# Error
										else if err
											console.log 'bal-util.scandir: has failed on:', fileFullPath
											return tasks.exit(err)
										# Subtree
										else if subtreeCallback
											return subtreeCallback tasks.completer()
										# Complete
										else
											return tasks.complete()
									# Relative Path
									relativePath: fileRelativePath
									# Read Files
									readFiles: readFiles
								)
							
							else
								# Done
								return tasks.complete()
						
						# Action
						if dirAction
							return dirAction fileFullPath, fileRelativePath, complete
						else if dirAction is false
							return complete(err,true)
						else
							return complete(err,false)
					
					# File
					else
						# Prepare
						complete = (err,skip) ->
							# Error
							return tasks.exit(err)  if err
							
							# Exited
							return tasks.exit()  if tasks.exited

							# Handle
							if skip
								# Done
								return tasks.complete()
							else
								# Append
								list[fileRelativePath] = 'file'
								if readFiles
									fs.readFile fileFullPath, (err,data) ->
										return tasks.exit(err)  if err
										# Append
										tree[file] = data.toString()
										# Done
										return tasks.complete()
								else
									# Append
									tree[file] = true
									# Done
									return tasks.complete()
						
						# Action
						if fileAction
							return fileAction fileFullPath, fileRelativePath, complete
						else if fileAction is false
							return complete(err,true)
						else
							return complete(err,false)
		
		# Chain
		@
	

	# Copy a directory
	# next(err)
	cpdir: (srcPath,outPath,next) ->
		util.scandir(
			# Path
			srcPath
			# File
			(fileSrcPath,fileRelativePath,next) ->
				fileOutPath = outPath+'/'+fileRelativePath
				util.ensurePath require('path').dirname(fileOutPath), (err) ->
					# Error
					if err
						console.log 'bal-util.cpdir: failed to create the path for the file:',fileSrcPath
						return next?(err)
					# Success
					util.cp fileSrcPath, fileOutPath, (err) ->
						# Forward
						if err
							console.log 'bal-util.cpdir: failed to copy the child file:',fileSrcPath
						return next?(err)
			# Dir
			null
			# Completed
			next
		)

		# Chain
		@
	

	# Remove a directory
	# next(err)
	rmdir: (parentPath,next) ->
		path = require('path')
		path.exists parentPath, (exists) ->
			# Skip
			return next?()  unless exists
			# Remove
			util.scandir(
				# Path
				parentPath
				
				# File
				(fileFullPath,fileRelativePath,next) ->
					fs.unlink fileFullPath, (err) ->
						# Forward
						if err
							console.log 'bal-util.rmdir: failed to remove the child file:', fileFullPath
						return next?(err)
				
				# Dir
				(fileFullPath,fileRelativePath,next) ->
					next? null, false, (next) ->
						fs.rmdir fileFullPath, (err) ->
							# Forward
							if err
								console.log 'bal-util.rmdir: failed to remove the child directory:', fileFullPath
							return next?(err)
				
				# Completed
				(err,list,tree) ->
					# Error
					if err
						return next?(err, list, tree)
					# Success
					fs.rmdir parentPath, (err) ->
						# Forward
						if err
							console.log 'bal-util.rmdir: failed to remove the parent directory:', parentPath
						return next?(err, list, tree)
			)
		
		# Chain
		@

	# Write tree
	# next(err)
	writetree: (dstPath,tree,next) ->
		# Group
		tasks = new @Group (err) ->
			next?(err)
		
		# Ensure Destination
		util.ensurePath dstPath, (err) ->
			# Checks
			if err
				return tasks.exit err
			
			# Cycle
			for own fileRelativePath, value of tree
				++tasks.total
				fileFullPath = dstPath+'/'+fileRelativePath.replace(/^\/+/,'')
				if typeof value is 'object'
					util.writetree fileFullPath, value, tasks.completer()
				else
					fs.writeFile fileFullPath, value, (err) ->
						if err
							console.log 'bal-util.writetree: writeFile failed on:',fileFullPath
						return tasks.complete err
			
			# Empty?
			if tasks.total is 0
				tasks.exit()

			# Return
			return
		
		# Chain
		@

	# Read path
	# Reads a path be it local or remote
	# next(err,data)
	readPath: (filePath,next) ->
		if /^http/.test(filePath)
			request = require 'request'  unless request
			request filePath, (err,response,data) =>
				return next?(err)  if err
				return next?(null,data)
		else
			fs.readFile filePath, (err,data) ->
				return next?(err)  if err
				return next?(null,data)
		
		# Chain
		@
	

	# =================================
	# Versions

	# Version Compare
	# http://phpjs.org/functions/version_compare
	# MIT Licensed http://phpjs.org/pages/license
	versionCompare: (v1,operator,v2) ->
		i = x = compare = 0
		vm =
			'dev': -6
			'alpha': -5
			'a': -5
			'beta': -4
			'b': -4
			'RC': -3
			'rc': -3
			'#': -2
			'p': -1
			'pl': -1

		prepVersion = (v) ->
			v = ('' + v).replace(/[_\-+]/g, '.')
			v = v.replace(/([^.\d]+)/g, '.$1.').replace(/\.{2,}/g, '.')
			if !v.length
				[-8]
			else
				v.split('.')

		numVersion = (v) ->
			if !v
				0
			else
				if isNaN(v)
					vm[v] or -7
				else
					parseInt(v, 10)
		
		v1 = prepVersion(v1)
		v2 = prepVersion(v2)
		x = Math.max(v1.length, v2.length)

		for i in [0..x]
			if (v1[i] == v2[i])
				continue
			
			v1[i] = numVersion(v1[i])
			v2[i] = numVersion(v2[i])
			
			if (v1[i] < v2[i])
				compare = -1
				break
			else if v1[i] > v2[i]
				compare = 1
				break
		
		if !operator
			return compare

		result = 
			switch operator
				when '>', 'gt'
					compare > 0
				when '>=', 'ge'
					compare >= 0
				when '<=', 'le'
					compare <= 0
				when '==', '=', 'eq', 'is'
					compare == 0
				when '<>', '!=', 'ne', 'isnt'
					compare != 0
				when '', '<', 'lt'
					compare < 0
				else
					null
		
		# Return result
		result
	

	# Compare Package
	packageCompare: ({local,remote,newVersionCallback,sameVersionCallback,oldVersionCallback,errorCallback}) ->
		details = {}

		# Handler
		runCompare = ->
			if util.versionCompare(details.local.version, '<', details.remote.version)
				newVersionCallback?(details)
			else if util.versionCompare(details.local.version, '==', details.remote.version)
				sameVersionCallback?(details)
			else if util.versionCompare(details.local.version, '>', details.remote.version)
				oldVersionCallback?(details)
		
		# Read local
		util.readPath local, (err,data) ->
			return errorCallback?(err)  if err
			details.local = JSON.parse(data.toString())
			# Read remote
			util.readPath remote, (err,data) ->
				return errorCallback?(err)  if err
				details.remote = JSON.parse(data.toString())
				# Compare
				runCompare()
		
		# Chain
		@
	
	# Initialise git submodules
	# next(err,stdout,stderr)
	initGitSubmodules: (dirPath,next) ->
		# Create the child process
		child = util.exec(
			# Commands
			[
				'git submodule init'
				'git submodule update'
				'git submodule foreach --recursive "git init"'
				'git submodule foreach --recursive "git checkout master"'
				'git submodule foreach --recursive "git submodule init"'
				'git submodule foreach --recursive "git submodule update"'
			]
			
			# Options
			{
				cwd: dirPath
			}

			# Next
			next
		)

		# Return child process
		return child
	
	
	# Initialise node modules
	# next(err,stdout,stderr)
	initNodeModules: (dirPath,next) ->
		# Create the child process
		child = util.exec(
			# Commands
			[
				'npm install'
			]
			
			# Options
			{
				cwd: dirPath
			}

			# Next
			next
		)

		# Return child process
		return child
	

	# Git Pull
	# next(err,stdout,stderr)
	gitPull: (dirPath,url,next) ->
		# Create the child process
		child = exec(
			# Commands
			[
				"git init"
				"git remote add origin #{url}"
				"git pull origin master"
			]
			
			# Options
			{
				cwd: dirPath
			}

			# Next
			next
		)

		# Return the child process
		return child



# Export
module.exports = util