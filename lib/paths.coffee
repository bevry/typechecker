# Requires
fs = require('fs')
request = null
balUtilPaths = null
balUtilGroups = require("#{__dirname}/groups.coffee")


# =====================================
# Paths

balUtilPaths =

	# Copy a file
	# next(err)
	cp: (src,dst,next) ->
		fs.readFile src, 'binary', (err,data) ->
			# Error
			if err
				console.log 'balUtilPaths.cp: cp failed on:',src
				return next?(err)
			# Success
			fs.writeFile dst, data, 'binary', (err) ->
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
		path = require('path')
		p = p.replace /[\/\\]$/, ''
		path.exists p, (exists) ->
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
				fs.mkdir p, 0700, (err) ->
					path.exists p, (exists) ->
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
			path = parentPath + '/' + path
		return path
	

	# Is it a directory?
	# next(err,isDirectory)
	isDirectory: (fileFullPath,next) ->
		# Stat
		fs.stat fileFullPath, (err,fileStat) ->
			# Error
			if err
				console.log 'balUtilPaths.isDirectory: stat failed on:',fileFullPath
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
				tasks = new balUtilGroups.Group next
				tasks.total += files.length
			
				# Array
				for file in files
					@scan fileFullPath, fileAction, dirAction, tasks.completer()
				
				# Done
				return true
		
		# String
		if typeof files.charAt isnt 'undefined'
			balUtilPaths.isDirectory (err,isDirectory) ->
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
			next?(new Error 'balUtilPaths.scandir: unsupported files type:', typeof files, files)

		# Chain
		@
	

	# Scan a directory into a tree
	# next(err,tree)
	scantree: (dirPath,next) ->
		# Handle
		balUtilPaths.scandir(
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
			err = new Error('balUtilPaths.scandir: unknown arguments')
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
			err = new Error('balUtilPaths.scandir: parentPath is needed')
			if next
				return next?(err)
			else
				throw err

		# Return
		list = {}
		tree = {}

		# Group
		tasks = new balUtilGroups.Group (err) ->
			next?(err, list, tree)
		
		# Cycle
		fs.readdir parentPath, (err,files) ->
			# Check
			if tasks.exited
				return

			# Error
			else if err
				console.log 'balUtilPaths.scandir: readdir has failed on:', parentPath
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
				balUtilPaths.isDirectory fileFullPath, (err,isDirectory) ->
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

								# Recurse
								return balUtilPaths.scandir(
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
											console.log 'balUtilPaths.scandir: has failed on:', fileFullPath
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
		balUtilPaths.scandir(
			# Path
			srcPath
			# File
			(fileSrcPath,fileRelativePath,next) ->
				fileOutPath = outPath+'/'+fileRelativePath
				balUtilPaths.ensurePath require('path').dirname(fileOutPath), (err) ->
					# Error
					if err
						console.log 'balUtilPaths.cpdir: failed to create the path for the file:',fileSrcPath
						return next?(err)
					# Success
					balUtilPaths.cp fileSrcPath, fileOutPath, (err) ->
						# Forward
						if err
							console.log 'balUtilPaths.cpdir: failed to copy the child file:',fileSrcPath
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
			balUtilPaths.scandir(
				# Path
				parentPath
				
				# File
				(fileFullPath,fileRelativePath,next) ->
					fs.unlink fileFullPath, (err) ->
						# Forward
						if err
							console.log 'balUtilPaths.rmdir: failed to remove the child file:', fileFullPath
						return next?(err)
				
				# Dir
				(fileFullPath,fileRelativePath,next) ->
					next? null, false, (next) ->
						fs.rmdir fileFullPath, (err) ->
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
					fs.rmdir parentPath, (err) ->
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
		tasks = new balUtilGroups.Group (err) ->
			next?(err)
		
		# Ensure Destination
		balUtilPaths.ensurePath dstPath, (err) ->
			# Checks
			if err
				return tasks.exit err
			
			# Cycle
			for own fileRelativePath, value of tree
				++tasks.total
				fileFullPath = dstPath+'/'+fileRelativePath.replace(/^\/+/,'')
				if typeof value is 'object'
					balUtilPaths.writetree fileFullPath, value, tasks.completer()
				else
					fs.writeFile fileFullPath, value, (err) ->
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
			fs.readFile filePath, (err,data) ->
				return next?(err)  if err
				return next?(null,data)
		
		# Chain
		@


# =====================================
# Export

module.exports = balUtilPaths