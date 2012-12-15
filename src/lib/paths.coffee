# Necessary
fsUtil = require('fs')
pathUtil = require('path')
balUtilFlow = require(__dirname+'/flow')
balUtilTypes = require(__dirname+'/types')

# Create a counter of all the open files we have
# As the filesystem will throw a fatal error if we have too many open files
global.numberOfOpenFiles ?= 0
global.maxNumberOfOpenFiles ?= process.env.NODE_MAX_OPEN_FILES ? 100
global.waitingToOpenFileDelay ?= 100


# =====================================
# Paths

balUtilPaths =

	# =================================
	# Locals

	# Common Ignore Patterns
	# These are files are directories commonly ignored when it comes with dealing with paths
	ignoreCommonPatterns:  process.env.NODE_IGNORE_COMMON_PATTERNS ? ///
		^(
			# Paths that start with something
			(
				~|          # vim, gedit, etc
				\.\#        # emacs
			).*|
			# Paths that end with something
			.*(
				\.swp       # vi
			)|
			# Paths that start with a dot and end with something
			\.(
				svn|
				git|
				hg|
				DS_Store
			)|
			# Paths that match any of the following
			node_modules|
			CVS|
			thumbs\.db|
			desktop\.ini
		)$
		///i

	# Allow the user to add their own custom ignore patterns
	ignoreCustomPatterns: process.env.NODE_IGNORE_CUSTOM_PATTERNS ? null

	# Text Extensions
	textExtensions: [
		'c'
		'coffee'
		'coffeekup'
		'cson'
		'css'
		'eco'
		'haml'
		'hbs'
		'htaccess'
		'htm'
		'html'
		'jade'
		'js'
		'json'
		'less'
		'md'
		'php'
		'phtml'
		'py'
		'rb'
		'rtf'
		'sass'
		'scss'
		'styl'
		'stylus'
		'text'
		'txt'
		'xml'
		'yaml'
	].concat (process.env.TEXT_EXTENSIONS or '').split(/[\s,]+/)

	# Binary Extensions
	binaryExtensions: [
		'dds'
		'eot'
		'gif'
		'ico'
		'jar'
		'jpeg'
		'jpg'
		'pdf'
		'png'
		'swf'
		'tga'
		'ttf'
		'zip'
	].concat (process.env.BINARY_EXTENSIONS or '').split(/[\s,]+/)


	# =====================================
	# Open and Close Files

	# Allows us to open files safely
	# by tracking the amount of open files we have

	# Open a file
	# Pass your callback to fire when it is safe to open the file
	openFile: (next) ->
		if global.numberOfOpenFiles < 0
			throw new Error("balUtilPaths.openFile: the numberOfOpenFiles is [#{global.numberOfOpenFiles}] which should be impossible...")
		if global.numberOfOpenFiles >= global.maxNumberOfOpenFiles
			setTimeout(
				-> balUtilPaths.openFile(next)
				global.waitingToOpenFileDelay
			)
		else
			++global.numberOfOpenFiles
			next()
		@

	# Close a file
	# Call this once you are done with that file
	closeFile: (next) ->
		--global.numberOfOpenFiles
		next?()
		@


	# =====================================
	# Standard

	# Read File
	# next(err)
	readFile: (path,encoding,next) ->
		# Prepare
		unless next?
			next = encoding
			encoding = null

		# Read
		balUtilPaths.openFile -> fsUtil.readFile path, encoding, (err,data) ->
			balUtilPaths.closeFile()
			return next(err,data)

		# Chain
		@

	# Write File
	# next(err)
	writeFile: (path,data,encoding,next) ->
		# Prepare
		unless next?
			next = encoding
			encoding = null

		# Ensure path
		balUtilPaths.ensurePath pathUtil.dirname(path), (err) ->
			# Error
			return next(err)  if err

			# Write data
			balUtilPaths.openFile -> fsUtil.writeFile path, data, encoding, (err) ->
				balUtilPaths.closeFile()
				return next(err)

		# Chain
		@

	# Mkdir
	# next(err)
	mkdir: (path,mode,next) ->
		# Prepare
		unless next?
			next = mode
			mode = null

		# Action
		balUtilPaths.openFile -> fsUtil.mkdir path, mode, (err) ->
			balUtilPaths.closeFile()
			return next(err)

		# Chain
		@

	# Stat
	# next(err,stat)
	stat: (path,next) ->
		balUtilPaths.openFile -> fsUtil.stat path, (err,stat) ->
			balUtilPaths.closeFile()
			return next(err,stat)

		# Chain
		@

	# Readdir
	# next(err,files)
	readdir: (path,next) ->
		balUtilPaths.openFile ->
			fsUtil.readdir path, (err,files) ->
				balUtilPaths.closeFile()
				return next(err,files)

		# Chain
		@

	# Unlink
	# next(err)
	unlink: (path,next) ->
		# Stat
		balUtilPaths.openFile -> fsUtil.unlink path, (err) ->
			balUtilPaths.closeFile()
			return next(err)

		# Chain
		@

	# Rmdir
	# next(err)
	rmdir: (path,next) ->
		# Stat
		balUtilPaths.openFile -> fsUtil.rmdir path, (err) ->
			balUtilPaths.closeFile()
			return next(err)

		# Chain
		@

	# Exists
	# next(err)
	exists: (path,next) ->
		# Exists function
		exists = fsUtil.exists or pathUtil.exists

		# Action
		balUtilPaths.openFile -> exists path, (exists) ->
			balUtilPaths.closeFile()
			return next(exists)

		# Chain
		@

	# Exits Sync
	# next(err)
	existsSync: (path) ->
		# Exists function
		existsSync = fsUtil.existsSync or pathUtil.existsSync

		# Action
		result = existsSync(path)

		# Return
		result


	# =====================================
	# Encoding

	# Is Text
	# Determine whether or not a file is a text or binary file
	# determined by extension checks first
	# if unknown extension, then fallback on encoding detection
	# we do this as encoding detection cannot guarantee everything
	# especially for chars between utf8 and utf16
	isTextSync: (filename,buffer) ->
		# Prepare
		isText = null

		# Test extensions
		if filename
			# Extract filename
			filename = pathUtil.basename(filename).split('.')
			# Cycle extensions
			for extension in filename
				if extension in balUtilPaths.textExtensions
					isText = true
					break
				if extension in balUtilPaths.binaryExtensions
					isText = false
					break

		# Fallback to encoding if extension check was not enough
		if buffer and isText is null
			isText = balUtilPaths.getEncodingSync(buffer) is 'utf8'

		# Return our result
		return isText

	# Get the encoding of a buffer
	isText: (filename,buffer,next) ->
		# Fetch and wrap result
		result = @isTextSync(filename,buffer)
		if result instanceof Error
			next(err)
		else
			next(null,result)

		# Chain
		@


	# Get the encoding of a buffer
	# We fetch a bunch chars from the start, middle and end of the buffer
	# we check all three, as doing only start was not enough, and doing only middle was not enough
	# so better safe than sorry
	getEncodingSync: (buffer,opts) ->
		# Prepare
		textEncoding = 'utf8'
		binaryEncoding = 'binary'

		# Discover
		unless opts?
			# Start
			chunkLength = 24
			encoding = balUtilPaths.getEncodingSync(buffer,{chunkLength,chunkBegin})
			if encoding is textEncoding
				# Middle
				chunkBegin = Math.max(0, Math.floor(buffer.length/2)-chunkLength)
				encoding = balUtilPaths.getEncodingSync(buffer,{chunkLength,chunkBegin})
				if encoding is textEncoding
					# End
					chunkBegin = Math.max(0, buffer.length-chunkLength)
					encoding = balUtilPaths.getEncodingSync(buffer,{chunkLength,chunkBegin})
		else
			# Extract
			{chunkLength,chunkBegin} = opts
			chunkLength ?= 24
			chunkBegin ?= 0
			chunkEnd = Math.min(buffer.length, chunkBegin+chunkLength)
			contentChunkUTF8 = buffer.toString(textEncoding,chunkBegin,chunkEnd)
			encoding = textEncoding

			# Detect encoding
			for i in [0...contentChunkUTF8.length]
				charCode = contentChunkUTF8.charCodeAt(i)
				if charCode is 65533 or charCode <= 8
					# 8 and below are control characters (e.g. backspace, null, eof, etc.)
					# 65533 is the unknown character
					# console.log(charCode, contentChunkUTF8[i])
					encoding = binaryEncoding
					break

		# Return encoding
		return encoding

	# Get the encoding of a buffer
	getEncoding: (buffer,opts,next) ->
		# Fetch and wrap result
		result = @getEncodingSync(buffer,opts)
		if result instanceof Error
			next(err)
		else
			next(null,result)

		# Chain
		@



	# =====================================
	# Our Extensions

	# Copy a file
	# Or rather overwrite a file, regardless of whether or not it was existing before
	# next(err)
	cp: (src,dst,next) ->
		# Copy
		balUtilPaths.readFile src, 'binary', (err,data) ->
			# Error
			if err
				console.log "balUtilPaths.cp: cp failed on: #{src}"
				return next(err)
			# Success
			balUtilPaths.writeFile dst, data, 'binary', (err) ->
				# Forward
				if err
					console.log "balUtilPaths.cp: writeFile failed on: #{dst}"
				return next(err)

		# Chain
		@


	# Get the parent path
	getParentPathSync: (p) ->
		parentPath = p.replace(/[\/\\][^\/\\]+$/, '')
		return parentPath


	# Ensure path exists
	# next(err,exists)
	ensurePath: (path,next) ->
		path = path.replace(/[\/\\]$/, '') # remove trailing slashes
		balUtilPaths.exists path, (exists) ->
			# Error
			return next(null,true)  if exists
			# Success
			parentPath = balUtilPaths.getParentPathSync(path)
			balUtilPaths.ensurePath parentPath, (err) ->
				# Error
				if err
					console.log "balUtilPaths.ensurePath: failed to ensure the path: #{parentPath}"
					return next(err,false)
				# Success
				balUtilPaths.mkdir path, '700', (err) ->
					balUtilPaths.exists path, (exists) ->
						# Error
						if not exists
							console.log "balUtilPaths.ensurePath: failed to create the directory: #{path}"
							return next(new Error "Failed to create the directory: #{path}")
						# Success
						next(null,false)
		# Chain
		@


	# Prefix path
	prefixPathSync: (path,parentPath) ->
		path = path.replace /[\/\\]$/, ''
		if /^([a-zA-Z]\:|\/)/.test(path) is false
			path = pathUtil.join(parentPath,path)
		return path


	# Is it a directory?
	# path can also be a stat object
	# next(err,isDirectory,fileStat)
	isDirectory: (path,next) ->
		# Check if path is a stat object
		if path?.isDirectory?
			return next(null, path.isDirectory(), path)

		# Otherwise fetch the stat and do the check
		else
			balUtilPaths.stat path, (err,stat) ->
				# Error
				if err
					console.log "balUtilPaths.isDirectory: stat failed on: #{path}"
					return next(err)
				# Success
				return next(null, stat.isDirectory(), stat)

		# Chain
		@


	# Generate a slug for a file
	generateSlugSync: (path) ->
		# Slugify
		result = path.replace(/[^a-zA-Z0-9]/g,'-').replace(/^-/,'').replace(/-+/,'-')

		# Return
		return result


	# Scan a directory into a list
	# next(err,list)
	scanlist: (path,next) ->
		# Handle
		balUtilPaths.scandir(
			path: path
			readFiles: true
			ignoreHiddenFiles: true
			next: (err,list) ->
				return next(err,list)
		)

		# Chain
		@

	# Scan a directory into a tree
	# next(err,tree)
	scantree: (path,next) ->
		# Handle
		balUtilPaths.scandir(
			path: path
			readFiles: true
			ignoreHiddenFiles: true
			next: (err,list,tree) ->
				return next(err,tree)
		)

		# Chain
		@

	# Test Ignore Patterns
	# opts={ignoreCommonPatterns,ignoreCustomPatterns}
	testIgnorePatterns: (path,opts={}) ->
		# Prepare
		basename = pathUtil.basename(path)
		opts.ignoreCommonPatterns ?= true
		opts.ignoreCustomPatterns ?= null

		# Alias
		if opts.ignoreCommonPatterns is true
			opts.ignoreCommonPatterns = balUtilPaths.ignoreCommonPatterns

		# Test
		result =
			(opts.ignoreCommonPatterns and opts.ignoreCommonPatterns.test(basename)) or
			(opts.ignoreCustomPatterns and opts.ignoreCustomPatterns.test(basename)) or
			false

		# Return
		return result


	# Recursively scan a directory
	# Usage:
	#	scandir(path,action,fileAction,dirAction,next)
	#	scandir({path,action,fileAction,dirAction,next,stat,recurse,readFiles,ignoreHiddenFiles,ignorePatterns})
	# Options:
	#	path: the path you want to read
	#	action: (default null) null, or a function to use for both the fileAction and dirACtion
	#	fileAction: (default null) null, or a function to run against each file, in the following format:
	#		fileAction(fileFullPath,fileRelativePath,next(err,skip),fileStat)
	#	dirAction: (default null) null, or a function to run against each directory, in the following format:
	#		dirAction(fileFullPath,fileRelativePath,next(err,skip),fileStat)
	#	next: (default null) null, or a function to run after the entire directory has been scanned, in the following format:
	#		next(err,list,tree)
	#	stat: (default null) null, or a file stat object for the path if we already have one (not actually used yet)
	#	recurse: (default true) null, or a boolean for whether or not to scan subdirectories too
	#	readFiles: (default false) null, or a boolean for whether or not we should read the file contents
	#	ignoreHiddenFiles: (default false) null, or a boolean for if we should ignore files starting with a dot
	#	ignoreCommonPatterns: (default false) null, boolean, or regex
	#		if null, becomes true
	#		if false, does not do any ignore patterns
	#		if true, defaults to balUtilPaths.ignoreCommonPatterns
	#		if regex, uses this value instead of balUtilPaths.ignoreCommonPatterns
	#	ignoreCustomPatterns: (default false) null, boolean, or regex (same as ignorePatterns but for ignoreCustomPatterns instead)
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
				return next(err)
			else
				throw err

		# Prepare defaults
		options.recurse ?= true
		options.readFiles ?= false
		options.ignoreHiddenFiles ?= false
		options.ignoreCommonPatterns ?= false

		# Action
		if options.action?
			options.fileAction ?= options.action
			options.dirAction ?= options.action

		# Ignore Patterns
		if options.ignoreCommonPatterns is true
			options.ignoreCommonPatterns = balUtilPaths.ignoreCommonPatterns

		# Check needed
		if options.parentPath and !options.path
			options.path = options.parentPath
		if !options.path
			err = new Error('balUtilPaths.scandir: path is needed')
			if next
				return next(err)
			else
				throw err

		# Group
		tasks = new balUtilFlow.Group (err) ->
			return options.next(err, list, tree)

		# Cycle
		balUtilPaths.readdir options.path, (err,files) ->
			# Checks
			if tasks.exited
				return
			# Error
			else if err
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
				isIgnoredFile = balUtilPaths.testIgnorePatterns(file,{
					ignoreCommonPatterns: options.ignoreCommonPatterns
					ignoreCustomPatterns: options.ignoreCustomPatterns
				})
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
								if options.readFiles
									# Read file
									balUtilPaths.readFile fileFullPath, (err,data) ->
										# Error?
										return tasks.exit(err)  if err
										# Append
										dataString = data.toString()
										list[fileRelativePath] = dataString
										tree[file] = dataString
										# Done
										return tasks.complete()
								else
									# Append
									list[fileRelativePath] = 'file'
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
				return next(err)
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
						return next(err)
					# The directory now does exist
					# So let's now place the file inside it
					balUtilPaths.cp fileSrcPath, fileOutPath, (err) ->
						# Forward
						if err
							console.log 'balUtilPaths.cpdir: failed to copy the child file:',fileSrcPath
						return next(err)
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
				return next(err)
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
						return next(err)
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
								return next(err)
						# The out path is new enough
						else
							return next()
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


	# Remove a directory deeply
	# next(err)
	rmdirDeep: (parentPath,next) ->
		balUtilPaths.exists parentPath, (exists) ->
			# Skip
			return next()  unless exists
			# Remove
			balUtilPaths.scandir(
				# Path
				parentPath

				# File
				(fileFullPath,fileRelativePath,next) ->
					balUtilPaths.unlink fileFullPath, (err) ->
						# Forward
						if err
							console.log 'balUtilPaths.rmdirDeep: failed to remove the child file:', fileFullPath
						return next(err)

				# Dir
				(fileFullPath,fileRelativePath,next) ->
					next null, false, (next) ->
						balUtilPaths.rmdirDeep fileFullPath, (err) ->
							# Forward
							if err
								console.log 'balUtilPaths.rmdirDeep: failed to remove the child directory:', fileFullPath
							return next(err)

				# Completed
				(err,list,tree) ->
					# Error
					if err
						return next(err, list, tree)
					# Success
					balUtilPaths.rmdir parentPath, (err) ->
						# Forward
						if err
							console.log 'balUtilPaths.rmdirDeep: failed to remove the parent directory:', parentPath
						return next(err, list, tree)
			)

		# Chain
		@


	# Write tree
	# next(err)
	writetree: (dstPath,tree,next) ->
		# Group
		tasks = new balUtilFlow.Group (err) ->
			next(err)

		# Ensure Destination
		balUtilPaths.ensurePath dstPath, (err) ->
			# Checks
			if err
				return tasks.exit err

			# Cycle
			for own fileRelativePath, value of tree
				++tasks.total
				fileFullPath = pathUtil.join( dstPath, fileRelativePath.replace(/^\/+/,'') )
				if balUtilTypes.isObject(value)
					balUtilPaths.writetree fileFullPath, value, tasks.completer()
				else
					balUtilPaths.writeFile fileFullPath, value, (err) ->
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
			requestOptions = require('url').parse(filePath)
			http = if requestOptions.protocol is 'https:' then require('https') else require('http')
			http
				.get requestOptions, (res) ->
					data = ''
					res.on 'data', (chunk) ->
						data += chunk
					res.on 'end', ->
						locationHeader = res.headers?.location or null
						if locationHeader and locationHeader isnt requestOptions.href
							# Follow the redirect
							return balUtilPaths.readPath(locationHeader,next)
						else
							# All done
							return next(null,data)
				.on 'error', (err) ->
					return next(err)
		else
			balUtilPaths.readFile filePath, (err,data) ->
				return next(err)  if err
				return next(null,data)

		# Chain
		@


	# Empty
	# Check if the file does not exist, or is empty
	# next(err,empty)
	empty: (filePath,next) ->
		# Check if we exist
		balUtilPaths.exists filePath, (exists) ->
			# Return empty if we don't exist
			return next(null,true)  unless exists

			# We do exist, so check if we have content
			balUtilPaths.stat filePath, (err,stat) ->
				# Check
				return next(err)  if err
				# Return whether or not we are actually empty
				return next(null,stat.size is 0)

		# Chain
		@


	# Is Path Older Than
	# Checks if a path is older than a particular amount of millesconds
	# next(err,older)
	# older will be null if the path does not exist
	isPathOlderThan: (aPath,bInput,next) ->
		# Handle mtime
		bMtime = null
		if balUtilTypes.isNumber(bInput)
			mode = 'time'
			bMtime = new Date(new Date() - bInput)
		else
			mode = 'path'
			bPath = bInput

		# Check if the path exists
		balUtilPaths.empty aPath, (err,empty) ->
			# If it doesn't then we should return right away
			return next(err,null)  if empty or err

			# We do exist, so let's check how old we are
			balUtilPaths.stat aPath, (err,aStat) ->
				# Check
				return next(err)  if err

				# Prepare
				compare = ->
					# Time comparison
					if aStat.mtime < bMtime
						older = true
					else
						older = false

					# Return result
					return next(null,older)

				# Perform the comparison
				if mode is 'path'
					# Check if the bPath exists
					balUtilPaths.empty bPath, (err,empty) ->
						# Return result if we are empty
						return next(err,null)  if empty or err

						# It does exist so lets get the stat
						balUtilPaths.stat bPath, (err,bStat) ->
							# Check
							return next(err)  if err

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