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
			if exists then return next false
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
						return next false
	
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
			return next false, fileStat.isDirectory()
	
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
				return next false, fileFullPath, fileRelativePath
	

	# Generate a slug for a file
	generateSlugSync: (fileFullPath) ->
		# Slugify
		result = fileFullPath.replace(/[^a-zA-Z0-9]/g,'-').replace(/^-/,'').replace(/-+/,'-')

		# Return
		return result

	# Recursively scan a directory
	# fileAction(fileFullPath,fileRelativePath,next(err)) or false
	# dirAction(fileFullPath,fileRelativePath,next(err)) or false
	# next(err)
	scandir: (parentPath,fileAction,dirAction,next,relativePath) ->
		# Return
		list = {}
		tree = {}

		# Async
		completed = 0
		total = 0
		exited = false
		complete = (err=false) ->
			if exited is false
				if err
					return exit err
				else
					++completed
					if completed is total
						return exit false
		exit = (err=false) ->
			if exited is false
				exited = true
				#console.log 'bal-util.scandir: args:', [err, list, tree]
				next err, list, tree
		
		#console.log 'bal-util.scandir: called on:', parentPath
		
		# Cycle
		fs.readdir parentPath, (err,files) ->
			# Check
			if exited
				return

			# Error
			else if err
				console.log 'bal-util.scandir: readdir has failed on:', parentPath
				return exit err
			
			# Empty?
			else if !files.length
				return exit false
			
			# Cycle
			else files.forEach (file) ->
				# Prepare
				++total
				fileFullPath = parentPath+'/'+file
				fileRelativePath = (if relativePath then relativePath+'/' else '')+file

				# IsDirectory
				#console.log 'bal-util.scandir: calling isDirectory on:', fileFullPath
				util.isDirectory fileFullPath, (err,isDirectory) ->
					# Check
					if exited
						return
					
					# Error
					else if err
						console.log 'bal-util.scandir: isDirectory has failed on:', fileFullPath
						return exit err
					
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
							(err,list,_tree) ->
								# Append
								tree[file] = _tree

								# Check
								if exited
									return
								# Error
								else if err
									console.log 'bal-util.scandir: has failed on:', fileFullPath
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
						# Append
						list[fileRelativePath] = 'file'
						tree[file] = true
						
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
	rmdir: (parentPath,next,debug=true) ->
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
						if err
							console.log 'bal-util.rmdir: failed to remove the child file:', fileFullPath
						else if debug
							console.log 'bal-util.rmdir: removed the child file:', fileFullPath
						return next err
				# Dir
				(fileFullPath,fileRelativePath,next) ->
					fs.rmdir fileFullPath, (err) ->
						# Forward
						if err
							console.log 'bal-util.rmdir: failed to remove the child directory:', fileFullPath
						else if debug
							console.log 'bal-util.rmdir: removed the child directory:', fileFullPath
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
						else if debug
							console.log 'bal-util.rmdir: removed the parent directory:', parentPath
						return next err, list, tree
			)
	
	# Write tree
	# next(err)
	writetree: (dstPath,tree,next) ->
		# Async
		completed = 0
		total = 0
		exited = false
		complete = (err=false) ->
			if exited is false
				if err
					return exit err
				else
					++completed
					if completed is total
						return exit false
		exit = (err=false) ->
			if exited is false
				exited = true
				next err
		
		# Ensure Destination
		util.ensurePath dstPath, (err) ->
			# Checks
			if err
				return exit err
			
			# Cycle
			for own fileRelativePath, value of tree
				++total
				fileFullPath = dstPath+'/'+fileRelativePath.replace(/^\/+/,'')
				#console.log 'bal-util.writetree: handling:', fileFullPath, typeof value
				if typeof value is 'object'
					util.writetree fileFullPath, value, complete
				else
					fs.writeFile fileFullPath, value, (err) ->
						if err
							console.log 'bal-util.writetree: writeFile failed on:',fileFullPath
						return complete err
			
			# Empty?
			if total is 0
				complete()

			# Return
			return
		
		# Return
		return
			
# Export
module.exports = util