# Requirements
fs = require 'fs'
path = require 'path'
request = null

# Types
# A higher level typeof
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
			task()
		
	# A task has completed
	complete: (err=false) ->
		if @exited is false
			if err
				return @exit err
			else
				++@completed
				if @completed is @total
					return @exit()
				else if @mode is 'sync'
					@nextTask()
	
	# Alias for complete
	completer: ->
		return (err) => @complete err
	
	# The group has finished
	exit: (err=false) ->
		if @exited is false
			@exited = true
			@next err
		else
			@next new Error 'Group has already exited'
	
	# Push a new task to the group
	push: (task) ->
		++@total
		@queue.push task
	
	# Run the tasks
	run: ->
		if @mode is 'sync'
			@queueIndex = 0
			if @queue[@queueIndex]?
				task = @queue[@queueIndex]
				task()
		else
			for task in @queue
				task()
	
	# Async
	async: ->
		@mode = 'async'
		@run()
	
	# Sync
	sync: ->
		@mode = 'sync'
		@run()


# Util
# A series of utility functions to help speed up node.js development
util =

	# Group
	Group: Group

	# Parallel
	parallel: (tasks,next) ->
		# Create group
		group = new @Group (err) ->
			next err
		group.total = tasks.length
		
		# Run tasks
		for task in tasks
			task group.completer()
	
	# Type
	type: type

	# Copy a file
	# next(err)
	cp: (src,dst,next) ->
		fs.readFile src, 'binary', (err,data) ->
			# Error
			if err
				console.log 'bal-util.cp: cp failed on:',src
				return next err
			# Success
			fs.writeFile dst, data, 'binary', (err) ->
				# Forward
				if err
					console.log 'bal-util.cp: writeFile failed on:',dst
				return next err
	
	# Get the parent path
	getParentPathSync: (p) ->
		parentPath = p.replace /[\/\\][^\/\\]+$/, ''
		return parentPath
	
	# Ensure path exists
	# next(err)
	ensurePath: (p,next) ->
		p = p.replace /[\/\\]$/, ''
		path.exists p, (exists) ->
			# Error 
			if exists then return next()
			# Success
			parentPath = util.getParentPathSync p
			util.ensurePath parentPath, (err) ->
				# Error
				if err
					console.log 'bal-util.ensurePath: failed to ensure the path:',parentPath
					return next err
				# Success
				fs.mkdir p, 0700, (err) ->
					path.exists p, (exists) ->
						# Error
						if not exists
							console.log 'bal-util.ensurePath: failed to create the directory:',p
							return next new Error 'Failed to create the directory '+p
						# Success
						return next()
	
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
				return next err
			# Success
			return next null, fileStat.isDirectory()
	
	# Resolve file path
	# next(err,fileFullPath,fileRelativePath)
	resolvePath: (srcPath,parentPath,next) ->
		fs.realpath srcPath, (err,fileFullPath) ->
			# Error 
			if err
				console.log 'bal-util.resolvePath: realpath failed on:',srcPath
				return next err, srcPath
			# Check
			else if fileFullPath.substring(0,parentPath.length) isnt parentPath
				err = new Error 'Hacker! Tried to create a file outside our working directory: '+fileFullPath
				return next err, fileFullPath, false
			# Success
			else
				fileRelativePath = fileFullPath.substring parentPath.length
				return next null, fileFullPath, fileRelativePath
	

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
				tasks = new util.Group (err) -> next err
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
					return next err
				
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
			next new Error 'bal-util.scandir: unsupported files type:', typeof files, files

	# Recursively scan a directory
	# fileAction(fileFullPath,fileRelativePath,next(err)) or false
	# dirAction(fileFullPath,fileRelativePath,next(err)) or false
	# next(err)
	scandir: (parentPath,fileAction,dirAction,next,relativePath) ->
		# Return
		list = {}
		tree = {}

		# Group
		tasks = new @Group (err) ->
			next err, list, tree
		
		# Cycle
		fs.readdir parentPath, (err,files) ->
			# Check
			if tasks.exited
				return

			# Error
			else if err
				console.log 'bal-util.scandir: readdir has failed on:', parentPath
				return tasks.exit err
			
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
						return tasks.exit err
					
					# Directory
					else if isDirectory
						# Append
						list[fileRelativePath] = 'dir'
						tree[file] = {}

						# Recurse
						util.scandir(
							# Path
							fileFullPath
							# File
							fileAction
							# Dir
							dirAction
							# Completed
							(err,_list,_tree) ->
								# Merge
								tree[file] = _tree
								for own filePath, fileType of _list
									list[filePath] = fileType

								# Check
								if tasks.exited
									return
								# Error
								else if err
									console.log 'bal-util.scandir: has failed on:', fileFullPath
									return tasks.exit err
								# Action
								else if dirAction
									return dirAction fileFullPath, fileRelativePath, tasks.completer()
								# Complete
								else
									return tasks.complete()
							# Relative Path
							fileRelativePath
						)
					
					# File
					else
						# Append
						list[fileRelativePath] = 'file'
						tree[file] = true
						
						# Action
						if fileAction
							return fileAction fileFullPath, fileRelativePath, tasks.completer()
						# Complete
						else
							return tasks.complete()
	
	# Copy a directory
	# next(err)
	cpdir: (srcPath,outPath,next) ->
		util.scandir(
			# Path
			srcPath
			# File
			(fileSrcPath,fileRelativePath,next) ->
				fileOutPath = outPath+'/'+fileRelativePath
				util.ensurePath path.dirname(fileOutPath), (err) ->
					# Error
					if err
						console.log 'bal-util.cpdir: failed to create the path for the file:',fileSrcPath
						return next err
					# Success
					util.cp fileSrcPath, fileOutPath, (err) ->
						# Forward
						if err
							console.log 'bal-util.cpdir: failed to copy the child file:',fileSrcPath
						return next err
			# Dir
			false
			# Completed
			next
		)
	
	# Remove a directory
	# next(err)
	rmdir: (parentPath,next) ->
		path.exists parentPath, (exists) ->
			# Skip
			if not exists then return next()
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
						return next err
				# Dir
				(fileFullPath,fileRelativePath,next) ->
					fs.rmdir fileFullPath, (err) ->
						# Forward
						if err
							console.log 'bal-util.rmdir: failed to remove the child directory:', fileFullPath
						return next err
				# Completed
				(err,list,tree) ->
					# Error
					if err
						return next err, list, tree
					# Success
					fs.rmdir parentPath, (err) ->
						# Forward
						if err
							console.log 'bal-util.rmdir: failed to remove the parent directory:', parentPath
						return next err, list, tree
			)
	
	# Write tree
	# next(err)
	writetree: (dstPath,tree,next) ->
		# Group
		tasks = new @Group (err) ->
			next err
		
		# Ensure Destination
		util.ensurePath dstPath, (err) ->
			# Checks
			if err
				return tasks.exit err
			
			# Cycle
			for own fileRelativePath, value of tree
				++tasks.total
				fileFullPath = dstPath+'/'+fileRelativePath.replace(/^\/+/,'')
				#console.log 'bal-util.writetree: handling:', fileFullPath, typeof value
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
		
		# Return
		return
	
	# Expand a path
	# next(err,expandedPath)
	expandPath: (path,dir,{cwd,realpath},next) ->
		# Prepare
		cwd ?= false
		realpath ?= false
		expandedPath = null
		cwdPath = false
		if cwd
			if type.string cwd
				cwdPath = cwd
			else
				cwdPath = process.cwd()

		# Check
		unless type.string path
			return next new Error 'bal-util.expandPath: path needs to be a string'
		unless type.string dir
			return next new Error 'bal-util.expandPath: dir needs to be a string'
	
		# Absolute path
		if /^\/|\:/.test path
			# Use it
			expandedPath = path
		
		# Relative Path
		else
			# CWD Path
			if cwd and /^\./.test path
				expandedPath = cwdPath + '/' + path
			# Relative Path
			else # /^[a-zA-Z]/
				expandedPath = dir + '/' + path
		
		# Realpath?
		if realpath
			fs.realpath expandedPath, (err,fileFullPath) ->
				# Error 
				if err
					console.log 'bal-util.expandPath: realpath failed on:',expandedPath
					return next err, expandedPath
			
				# Success
				return next null, fileFullPath
		
		# Done
		else
			return next null, expandedPath
		
		# Done
		return
	
	# Expand a series of paths
	# next(err,expandedPaths)
	expandPaths: (paths,dir,options,next) ->
		# Prepare
		options or= {}
		expandedPaths = []
		tasks = new @Group (err) ->
			next err, expandedPaths
		tasks.total += paths.length

		# Cycle
		for path in paths
			# Expand
			@expandPath path, dir, options, (err,expandedPath) ->
				# Error
				if err
					return tasks.exit err
				
				# Store
				expandedPaths.push expandedPath
				tasks.complete err

		# Empty?
		unless paths.length
			tasks.exit()
		
		# Done
		return
	
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
	
	# Compare Package
	packageCompare: ({local,remote,newVersionCallback,oldVersionCallback,errorCallback}) ->
		details = {}
		try
			details.local = JSON.parse fs.readFileSync(local).toString()
			request = require 'request'  unless request
			request remote, (err,response,body) =>
				if not err and response.statusCode is 200
					details.remote = JSON.parse body
					unless @versionCompare(details.local.version, '>=', details.remote.version)
						newVersionCallback(details)  if newVersionCallback
					else
						oldVersionCallback(details)  if oldVersionCallback
		catch err
			errorCallback(err)  if errorCallback


# Export
module.exports = util