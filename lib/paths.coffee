# Requires
fs = require('fs')
pathUtil = require('path')
request = null
balUtilPaths = null
balUtilFlow = require(pathUtil.join __dirname, 'flow.coffee')

# Create a counter of all the open files we have
# As the filesystem will throw a fatal error if we have too many open files
global.numberOfOpenFiles ?= 0
global.maxNumberOfOpenFiles ?= 500


# =====================================
# Paths

balUtilPaths =

	# =====================================
	# Open and Close Files

	# Allows us to open files safely
	# by tracking the amount of open files we have

	# Open a file
	# Pass your callback to fire when it is safe to open the file
	openFile: (next) ->
		if global.numberOfOpenFiles >= global.maxNumberOfOpenFiles
			setTimeout(
				->
					balUtilPaths.openFile(next)
				,50
			)
		else
			++global.numberOfOpenFiles
			next?()
		@

	# Close a file
	# Call this once you are done with that file
	closeFile: (next) ->
		--global.numberOfOpenFiles
		next?()
		@


	# =====================================
	# Our Extensions

	# Copy a file
	# Or rather overwrite a file, regardless of whether or not it was existing before
	# next(err)
	cp: (src,dst,next) ->
		balUtilPaths.openFile -> fs.readFile src, 'binary', (err,data) ->
			balUtilPaths.closeFile()
			# Error
			if err
				console.log 'balUtilPaths.cp: cp failed on:',src
				return next?(err)
			# Success
			balUtilPaths.openFile -> fs.writeFile dst, data, 'binary', (err) ->
				balUtilPaths.closeFile()
				# Forward
				if err
					console.log 'balUtilPaths.cp: writeFile failed on:',dst
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
		p = p.replace /[\/\\]$/, ''
		pathUtil.exists p, (exists) ->
			# Error 
			return next?()  if exists
			# Success
			parentPath = balUtilPaths.getParentPathSync p
			balUtilPaths.ensurePath parentPath, (err) ->
				# Error
				if err
					console.log 'balUtilPaths.ensurePath: failed to ensure the path:',parentPath
					return next?(err)
				# Success
				balUtilPaths.openFile -> fs.mkdir p, '700', (err) ->
					pathUtil.exists p, (exists) ->
						# Close
						balUtilPaths.closeFile()
						# Error
						if not exists
							console.log 'balUtilPaths.ensurePath: failed to create the directory:',p
							return next?(new Error 'Failed to create the directory '+p)
						# Success
						next?()
		# Chain
		@
	

	# Prefix path
	prefixPathSync: (path,parentPath) ->
		path = path.replace /[\/\\]$/, ''
		if /^([a-zA-Z]\:|\/)/.test(path) is false
			path = pathUtil.join(parentPath,path)
		return path
	

	# Is it a directory?
	# next(err,isDirectory,fileStat)
	isDirectory: (fileFullPath,next) ->
		# Stat
		balUtilPaths.openFile -> fs.stat fileFullPath, (err,fileStat) ->
			balUtilPaths.closeFile()
			# Error
			if err
				console.log 'balUtilPaths.isDirectory: stat failed on:',fileFullPath
				return next?(err)
			# Success
			return next?(null, fileStat.isDirectory(), fileStat)
		
		# Chain
		@
	
	
	# Generate a slug for a file
	generateSlugSync: (fileFullPath) ->
		# Slugify
		result = fileFullPath.replace(/[^a-zA-Z0-9]/g,'-').replace(/^-/,'').replace(/-+/,'-')

		# Return
		return result
		

	# Scan a directory into a tree
	# next(err,tree)
	scantree: (dirPath,next) ->
		# Handle
		balUtilPaths.scandir(
			path: dirPath
			readFiles: true
			ignoreHiddenFiles: true
			next: (err,list,tree) ->
				next?(err,tree)
		)

		# Chain
		@

	# Common Ignore Patterns
	# These are files are directories commonly ignored when it comes with dealing with paths
	commonIgnorePatterns: /^(\~|(\.(svn|git|hg|DS_Store))|node_modules|CVS|thumbs\.db|desktop\.ini)$/i

	# Recursively scan a directory
	# Usage:
	#	scandir(path,action,fileAction,dirAction,next)
	#	scandir({path,action,fileAction,dirAction,next,stat,recurse,readFiles,ignoreHiddenFiles,ignorePatterns})
	# Options:
	#	path: the path you want to read
	#	action: null, or a function to use for both the fileAction and dirACtion
	#	fileAction: null, or a function to run against each file, in the following format:
	#		fileAction(fileFullPath,fileRelativePath,next(err,skip),fileStat)
	#	dirAction: null, or a function to run against each directory, in the following format:
	#		dirAction(fileFullPath,fileRelativePath,next(err,skip),fileStat)
	#	next: null, or a function to run after the entire directory has been scanned, in the following format:
	#		next(err,list,tree)
	#	stat: null, or a file stat object for the path if we already have one
	#	recurse: null, or a boolean for whether or not to scan subdirectories too
	#	readFiles: null, or a boolean for whether or not we should read the file contents
	#	ignoreHiddenFiles: null, or a boolean for if we should ignore files starting with a dot
	#	ignorePatterns: null, or true (if true will use balUtilPaths.commonIgnorePatterns),
	#		or a regex to match paths against to determine if we should ignore them
	# Next Callback Arguments:
	#	err: null, or an error that has occured
	#	list: a collection of all the child nodes in a list/object format:
	#		{fileRelativePath: 'dir|file'}
	#	tree: a colleciton of all the child nodes in a tree format:
	#		{dir:{dir:{},file1:true}}
	#		if the readFiles option is true, then files will be returned with their contents instead
	scandir: (args...) ->
		# Prepare 
		list = {}
		tree = {}

		# Arguments
		if args.length is 1
			options = args[0]
		else if args.length >= 4
			options =
				path: args[0]
				fileAction: args[1] or null
				dirAction: args[2] or null
				next: args[3] or null
		else
			err = new Error('balUtilPaths.scandir: unsupported arguments')
			if next
				return next?(err)
			else
				throw err

		# Prepare defaults
		options.recurse ?= true
		options.readFiles ?= false
		options.ignoreHiddenFiles ?= false
		options.ignorePatterns ?= false

		# Action
		if options.action?
			options.fileAction ?= options.action
			options.dirAction ?= options.action

		# Ignore Patterns
		if options.ignorePatterns is true
			options.ignorePatterns = balUtilPaths.commonIgnorePatterns

		# Check needed
		if options.parentPath and !options.path
			options.path = options.parentPath
		if !options.path
			err = new Error('balUtilPaths.scandir: path is needed')
			if next
				return next?(err)
			else
				throw err

		# Group
		tasks = new balUtilFlow.Group (err) ->
			return options.next?(err, list, tree)
		
		# Cycle
		balUtilPaths.openFile -> fs.readdir options.path, (err,files) ->
			# Close
			balUtilPaths.closeFile()

			# Checks
			if tasks.exited
				return
			# Error
			else if err
				debugger
				console.log 'balUtilPaths.scandir: readdir has failed on:', options.path
				return tasks.exit(err)
			
			# Totals
			tasks.total += files.length

			# Empty?
			if !files.length
				return tasks.exit()
			
			# Cycle
			else files.forEach (file) ->
				# Check
				isHiddenFile = options.ignoreHiddenFiles and /^\./.test(file)
				isIgnoredFile = options.ignorePatterns and options.ignorePatterns.test(file)
				if isHiddenFile or isIgnoredFile
					return tasks.complete()

				# Prepare
				fileFullPath = pathUtil.join(options.path,file)
				fileRelativePath =
					if options.relativePath
						pathUtil.join(options.relativePath,file)
					else
						file

				# IsDirectory
				balUtilPaths.isDirectory fileFullPath, (err,isDirectory,fileStat) ->
					# Check
					if tasks.exited
						return
					
					# Error
					else if err
						console.log 'balUtilPaths.scandir: isDirectory has failed on:', fileFullPath
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

								# No Recurse
								unless options.recurse
									return tasks.complete()

								# Recurse
								else
									return balUtilPaths.scandir(
										# Path
										path: fileFullPath
										relativePath: fileRelativePath
										# Options
										fileAction: options.fileAction
										dirAction: options.dirAction
										readFiles: options.readFiles
										ignorePatterns: options.ignorePatterns
										ignoreHiddenFiles: options.ignoreHiddenFiles
										recurse: options.recurse
										stat: options.fileStat
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
												console.log 'balUtilPaths.scandir: has failed on:', fileFullPath
												return tasks.exit(err)
											# Subtree
											else if subtreeCallback
												return subtreeCallback tasks.completer()
											# Complete
											else
												return tasks.complete()
									)
							
							else
								# Done
								return tasks.complete()
						
						# Action
						if options.dirAction
							return options.dirAction(fileFullPath, fileRelativePath, complete, fileStat)
						else if options.dirAction is false
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
								if options.readFiles
									# Read file
									balUtilPaths.openFile -> fs.readFile fileFullPath, (err,data) ->
										# Close file
										balUtilPaths.closeFile()
										# Error?
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
						if options.fileAction
							return options.fileAction(fileFullPath, fileRelativePath, complete, fileStat)
						else if options.fileAction is false
							return complete(err,true)
						else
							return complete(err,false)
		
		# Chain
		@
	

	# Copy a directory
	# If the same file already exists, we will keep the source one
	# Usage:
	# 	cpdir({srcPath,outPath,next,[ignoreHiddenFiles],[ignorePatterns]})
	# 	cpdir(srcPath,outPath,next)
	# Callbacks:
	# 	next(err)
	cpdir: (args...) ->
		# Prepare
		if args.length is 1
			{srcPath,outPath,next,ignoreHiddenFiles,ignorePatterns} = args[0]
		else if args.length >= 3
			[srcPath,outPath,next] = args
		else
			err = new Error('balUtilPaths.cpdir: unknown arguments')
			if next
				return next?(err)
			else
				throw err

		# Create options
		scandirOptions = {
			path: srcPath
			fileAction: (fileSrcPath,fileRelativePath,next) ->
				# Prepare
				fileOutPath = pathUtil.join(outPath,fileRelativePath)
				# Ensure the directory that the file is going to exists
				balUtilPaths.ensurePath pathUtil.dirname(fileOutPath), (err) ->
					# Error
					if err
						console.log 'balUtilPaths.cpdir: failed to create the path for the file:',fileSrcPath
						return next?(err)
					# The directory now does exist
					# So let's now place the file inside it
					balUtilPaths.cp fileSrcPath, fileOutPath, (err) ->
						# Forward
						if err
							console.log 'balUtilPaths.cpdir: failed to copy the child file:',fileSrcPath
						return next?(err)
			next: next
		}

		# Extra options
		if ignoreHiddenFiles?
			scandirOptions.ignoreHiddenFiles = ignoreHiddenFiles
		if ignorePatterns?
			scandirOptions.ignorePatterns = ignorePatterns

		# Scan all the files in the diretory and copy them over asynchronously
		balUtilPaths.scandir(scandirOptions)

		# Chain
		@
	

	# Replace a directory
	# If the same file already exists, we will keep the newest one
	# Usage:
	# 	rpdir({srcPath,outPath,next,[ignoreHiddenFiles],[ignorePatterns]})
	# 	rpdir(srcPath,outPath,next)
	# Callbacks:
	# 	next(err)
	rpdir: (args...) ->
		# Prepare
		if args.length is 1
			{srcPath,outPath,next,ignoreHiddenFiles,ignorePatterns} = args[0]
		else if args.length >= 3
			[srcPath,outPath,next] = args
		else
			err = new Error('balUtilPaths.cpdir: unknown arguments')
			if next
				return next?(err)
			else
				throw err

		# Create options
		scandirOptions = {
			path: srcPath
			fileAction: (fileSrcPath,fileRelativePath,next) ->
				# Prepare
				fileOutPath = pathUtil.join(outPath,fileRelativePath)
				# Ensure the directory that the file is going to exists
				balUtilPaths.ensurePath pathUtil.dirname(fileOutPath), (err) ->
					# Error
					if err
						console.log 'balUtilPaths.rpdir: failed to create the path for the file:',fileSrcPath
						return next?(err)
					# Check if it is worthwhile copying that file
					balUtilPaths.isPathOlderThan fileOutPath, fileSrcPath, (err,older) ->
						# The src path has been modified since the out path was generated
						if older is true or older is null
							# The directory now does exist
							# So let's now place the file inside it
							balUtilPaths.cp fileSrcPath, fileOutPath, (err) ->
								# Forward
								if err
									console.log 'balUtilPaths.rpdir: failed to copy the child file:',fileSrcPath
								return next?(err)
						# The out path is new enough
						else
							return next?()
			next: next
		}

		# Extra options
		if ignoreHiddenFiles?
			scandirOptions.ignoreHiddenFiles = ignoreHiddenFiles
		if ignorePatterns?
			scandirOptions.ignorePatterns = ignorePatterns

		# Scan all the files in the diretory and copy them over asynchronously
		balUtilPaths.scandir(scandirOptions)

		# Chain
		@
	

	# Remove a directory
	# next(err)
	rmdir: (parentPath,next) ->
		pathUtil.exists parentPath, (exists) ->
			# Skip
			return next?()  unless exists
			# Remove
			balUtilPaths.scandir(
				# Path
				parentPath
				
				# File
				(fileFullPath,fileRelativePath,next) ->
					balUtilPaths.openFile -> fs.unlink fileFullPath, (err) ->
						balUtilPaths.closeFile()
						# Forward
						if err
							console.log 'balUtilPaths.rmdir: failed to remove the child file:', fileFullPath
						return next?(err)
				
				# Dir
				(fileFullPath,fileRelativePath,next) ->
					next? null, false, (next) ->
						balUtilPaths.openFile -> fs.rmdir fileFullPath, (err) ->
							balUtilPaths.closeFile()
							# Forward
							if err
								console.log 'balUtilPaths.rmdir: failed to remove the child directory:', fileFullPath
							return next?(err)
				
				# Completed
				(err,list,tree) ->
					# Error
					if err
						return next?(err, list, tree)
					# Success
					balUtilPaths.openFile -> fs.rmdir parentPath, (err) ->
						balUtilPaths.closeFile()
						# Forward
						if err
							console.log 'balUtilPaths.rmdir: failed to remove the parent directory:', parentPath
						return next?(err, list, tree)
			)
		
		# Chain
		@


	# Write tree
	# next(err)
	writetree: (dstPath,tree,next) ->
		# Group
		tasks = new balUtilFlow.Group (err) ->
			next?(err)

		# Ensure Destination
		balUtilPaths.ensurePath dstPath, (err) ->
			# Checks
			if err
				return tasks.exit err
			
			# Cycle
			for own fileRelativePath, value of tree
				++tasks.total
				fileFullPath = pathUtil.join( dstPath, fileRelativePath.replace(/^\/+/,'') )
				if typeof value is 'object'
					balUtilPaths.writetree fileFullPath, value, tasks.completer()
				else
					balUtilPaths.openFile -> fs.writeFile fileFullPath, value, (err) ->
						balUtilPaths.closeFile()
						if err
							console.log 'balUtilPaths.writetree: writeFile failed on:',fileFullPath
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
			request = require('request')  unless request
			request filePath, (err,response,data) =>
				return next?(err)  if err
				return next?(null,data)
		else
			balUtilPaths.openFile -> fs.readFile filePath, (err,data) ->
				balUtilPaths.closeFile()
				return next?(err)  if err
				return next?(null,data)
		
		# Chain
		@


	# Empty
	# Check if the file does not exist, or is empty
	# next(err,empty)
	empty: (filePath,next) ->
		# Check if we exist
		pathUtil.exists filePath, (exists) ->
			# Return empty if we don't exist
			return next?(null,true)  unless exists

			# We do exist, so check if we have content
			balUtilPaths.openFile -> fs.stat filePath, (err,stat) ->
				balUtilPaths.closeFile()
				# Check
				return next?(err)  if err
				# Return whether or not we are actually empty
				return next?(null,stat.size is 0)

		# Chain
		@


	# Is Path Older Than
	# Checks if a path is older than a particular amount of millesconds
	# next(err,older)
	# older will be null if the path does not exist
	isPathOlderThan: (aPath,bInput,next) ->
		# Handle mtime
		bMtime = null
		if typeof bInput is 'number'
			mode = 'time'
			bMtime = new Date(new Date() - bInput)
		else
			mode = 'path'
			bPath = bInput

		# Check if the path exists
		balUtilPaths.empty aPath, (err,empty) ->
			# If it doesn't then we should return right away
			return next?(err,null)  if empty or err

			# We do exist, so let's check how old we are
			balUtilPaths.openFile -> fs.stat aPath, (err,aStat) ->
				balUtilPaths.closeFile()

				# Check
				return next?(err)  if err

				# Prepare
				compare = ->
					# Time comparison
					if aStat.mtime < bMtime
						older = true
					else
						older = false

					# Return result
					return next?(null,older)

				# Perform the comparison
				if mode is 'path'
					# Check if the bPath exists
					balUtilPaths.empty bPath, (err,empty) ->
						# Return result if we are empty
						return next?(err,null)  if empty or err

						# It does exist so lets get the stat
						balUtilPaths.openFile -> fs.stat bPath, (err,bStat) ->
							balUtilPaths.closeFile()

							# Check
							return next?(err)  if err

							# Assign the outer bMtime variable
							bMtime = bStat.mtime

							# Perform the comparison
							return compare()
				else
					# We already have the bMtime
					return compare()

		# Chain
		@



# =====================================
# Export

module.exports = balUtilPaths