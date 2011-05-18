# Requirements
fs = require 'fs'
path = require 'path'

# Util
util =
	# Copy a file
	# next(err)
	cp: (src,dst,next) ->
		fs.readFile src, 'binary', (err,data) ->
			# Error
			if err then return next err
			# Success
			fs.writeFile dst, data, 'binary', (err) ->
				# Forward
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
			if exists then return next false
			# Success
			parentPath = util.getParentPathSync p
			util.ensurePath parentPath, (err) ->
				# Error
				if err then return next err
				# Success
				fs.mkdir p, 0700, (err) ->
					path.exists p, (exists) ->
						# Error
						if not exists then return next new Error 'Failed to create the directory '+p
						# Success
						return next false
	
	# Is it a directory?
	# next(err,isDirectory)
	isDirectory: (fileFullPath,next) ->
		# Stat
		fs.stat fileFullPath, (err,fileStat) ->
			# Error
			if err then return next err
			# Success
			return next false, fileStat.isDirectory()
	
	# Resolve file path
	# next(err,fileFullPath,fileRelativePath)
	resolvePath: (srcPath,parentPath,next) ->
		fs.realpath srcPath, (err,fileFullPath) ->
			# Error 
			if err
				return next err, srcPath
			# Check
			else if fileFullPath.substring(0,parentPath.length) isnt parentPath
				err = new Error 'Hacker! Tried to create a file outside our working directory: '+fileFullPath
				return next err, fileFullPath, false
			# Success
			else
				fileRelativePath = fileFullPath.substring parentPath.length
				return next false, fileFullPath, fileRelativePath
	

	# Generate a slug for a file
	generateSlugSync: (fileFullPath) ->
		# Slugify
		result = fileFullPath.replace(/[^a-zA-Z0-9]/g,'-').replace(/^-/,'').replace(/-+/,'-')

		# Return
		return result

	# Recursively scan a directory
	# next(err)
	scandir: (parentPath,fileAction,dirAction,next,relativePath) ->
		# Async
		completed = 0
		total = 0
		exited = false
		complete = ->
			unless exited
				++completed
				if completed is total
					return exit false
		exit = (err) ->
			unless exited
				exited = true
				next err
		
		# Cycle
		fs.readdir parentPath, (err,files) ->
			# Check
			if exited then return

			# Error
			else if err then return exit err
			
			# Skip
			else if !files.length then return exit false
			
			# Cycle
			else files.forEach (file) ->
				# Prepare
				++total
				fileFullPath = parentPath+'/'+file
				fileRelativePath = (if relativePath then relativePath+'/' else '')+file

				# IsDirectory
				util.isDirectory fileFullPath, (err,isDirectory) ->
					# Check
					if exited then return
					
					# Error
					else if err then return exit err
					
					# Directory
					else if isDirectory
						# Recurse
						util.scandir(
							# Path
							fileFullPath
							# File
							fileAction
							# Dir
							dirAction
							# Next
							(err) ->
								# Check
								if exited
									return
								# Error
								else if err
									return exit err
								# Action
								else if dirAction
									return dirAction fileFullPath, fileRelativePath, complete
								# Complete
								else
									return complete()
							# Relative Path
							fileRelativePath
						)
					
					# File
					else
						# Action
						if fileAction
							return fileAction fileFullPath, fileRelativePath, complete
						# Complete
						else
							return complete()

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
					if err then return next err
					# Success
					util.cp fileSrcPath, fileOutPath, (err) ->
						# Forawrd
						return next err
			# Dir
			false
			# Next
			next
		)
	
	# Remove a directory
	# next(err)
	rmdir: (parentPath,next) ->
		path.exists parentPath, (exists) ->
			# Skip
			if not exists then return next false
			# Remove
			util.scandir(
				# Path
				parentPath
				# File
				(fileFullPath,fileRelativePath,next) ->
					fs.unlink fileFullPath, (err) ->
						# Forward
						return next err
				# Dir
				(fileFullPath,fileRelativePath,next) ->
					fs.rmdir fileFullPath, (err) ->
						# Forward
						return next err
				# Next
				(err) ->
					# Error
					if err then return next err
					# Success
					fs.rmdir parentPath, (err) ->
						# Forward
						return next err
			)

# Export
module.exports = util