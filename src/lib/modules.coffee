# Requires
balUtilModules = null
balUtilFlow = require('./flow')
balUtilPaths = require('./paths')
balUtilTypes = require('./types')

# Prepare
isWindows = process?.platform?.indexOf('win') is 0

# Create a counter of all the open files we have
# As the filesystem will throw a fatal error if we have too many open files
global.numberOfOpenProcesses ?= 0
global.maxNumberOfOpenProcesses ?= process.env.NODE_MAX_OPEN_PROCESSES ? 30
global.waitingToOpenProcessDelay ?= 100


# =====================================
# Paths

balUtilModules =

	# =================================
	# Require

	# Require Fresh
	# Require the file without adding it into the cache
	requireFresh: (path) ->
		path = require('path').resolve(path)
		delete require.cache[path]  # clear require cache for the config file
		result = require(path)
		delete require.cache[path]  # clear require cache for the config file
		return result


	# =================================
	# Environments

	# Is Windows
	# Returns whether or not we are running on a windows machine
	isWindows: ->
		return isWindows

	# Get Locale Code
	getLocaleCode: (lang=null) ->
		lang ?= (process.env.LANG or '')
		localeCode = lang.replace(/\..+/,'').replace('-','_').toLowerCase() or null
		return localeCode

	# Get Language Code
	getLanguageCode: (localeCode=null) ->
		localeCode = balUtilModules.getLocaleCode(localeCode)
		languageCode = localeCode.replace(/^([a-z]+)[_-]([a-z]+)$/i,'$1').toLowerCase() or null
		return languageCode

	# Get Country Code
	getCountryCode: (localeCode=null) ->
		localeCode = balUtilModules.getLocaleCode(localeCode)
		countryCode = localeCode.replace(/^([a-z]+)[_-]([a-z]+)$/i,'$2').toLowerCase() or null
		return countryCode


	# =====================================
	# Open and Close Process

	# Allows us to open processes safely
	# by tracking the amount of open processes we have

	# Open a process
	# Pass your callback to fire when it is safe to open the process
	openProcess: (next) ->
		if global.numberOfOpenProcesses < 0
			throw new Error("balUtilModules.openProcess: the numberOfOpenProcesses is [#{global.numberOfOpenProcesses}] which should be impossible...")
		if global.numberOfOpenProcesses >= global.maxNumberOfOpenProcesses
			setTimeout(
				-> balUtilModules.openProcess(next)
				global.waitingToOpenProcessDelay
			)
		else
			++global.numberOfOpenProcesses
			next()
		@

	# Close a process
	# Call this once you are done with that process
	closeProcess: (next) ->
		--global.numberOfOpenProcesses
		next?()
		@


	# =================================
	# Spawn

	# Spawn
	# Wrapper around node's spawn command for a cleaner and more powerful API
	# next(err,stdout,stderr,code,signal)
	spawn: (command,opts,next) ->
		# Patience
		balUtilModules.openProcess ->
			# Prepare
			{spawn} = require('child_process')
			[opts,next] = balUtilFlow.extractOptsAndCallback(opts,next)

			# Prepare
			pid = null
			err = null
			stdout = ''
			stderr = ''

			# Prepare format
			if balUtilTypes.isString(command)
				command = command.split(' ')

			# Execute command
			if balUtilTypes.isArray(command)
				pid = spawn(command[0], command.slice(1), opts)
			else
				pid = spawn(command.command, command.args or [], command.options or opts)

			# Fetch
			pid.stdout.on 'data', (data) ->
				process.stdout.write(data)  if opts.output
				stdout += data.toString()
			pid.stderr.on 'data', (data) ->
				process.stderr.write(data)  if opts.output
				stderr += data.toString()

			# Wait
			pid.on 'exit', (code,signal) ->
				err = null
				if code isnt 0
					err = new Error(stderr or 'exited with a non-zero status code')
				balUtilModules.closeProcess()
				next(err,stdout,stderr,code,signal)

			# Stdin?
			if opts.stdin
				# Write the content to stdin
				pid.stdin.write(opts.stdin)
				pid.stdin.end()

		# Chain
		@

	# Spawn Multiple
	# next(err,results), results = [result...], result = [err,stdout,stderr,code,signal]
	spawnMultiple: (commands,opts,next) ->
		# Prepare
		[opts,next] = balUtilFlow.extractOptsAndCallback(opts,next)
		opts.tasksMode or= 'serial'
		results = []

		# Make sure we send back the arguments
		tasks = new balUtilFlow.Group opts.tasksMode, (err) ->
			next(err,results)

		# Prepare tasks
		unless balUtilTypes.isArray(commands)
			commands = [commands]

		# Add tasks
		for command in commands
			tasks.push {command}, (complete) ->
				balUtilModules.spawn @command, opts, (args...) ->
					err = args[0] or null
					results.push(args)
					complete(err)

		# Run the tasks
		tasks.run()

		# Chain
		@


	# =================================
	# Exec

	# Exec
	# Wrapper around node's exec command for a cleaner and more powerful API
	# next(err,stdout,stderr)
	exec: (command,opts,next) ->
		# Patience
		balUtilModules.openProcess ->
			# Prepare
			{exec} = require('child_process')
			[opts,next] = balUtilFlow.extractOptsAndCallback(opts,next)

			# Output
			if opts.output
				opts.stdio = 'inherit'
				delete opts.output

			# Execute command
			exec command, opts, (err,stdout,stderr) ->
				# Complete the task
				balUtilModules.closeProcess()
				next(err,stdout,stderr)

		# Chain
		@

	# Exec Multiple
	# next(err,results), results = [result...], result = [err,stdout,stderr]
	execMultiple: (commands,opts,next) ->
		# Prepare
		[opts,next] = balUtilFlow.extractOptsAndCallback(opts,next)
		opts.tasksMode or= 'serial'
		results = []

		# Make sure we send back the arguments
		tasks = new balUtilFlow.Group opts.tasksMode, (err) ->
			next(err,results)

		# Prepare tasks
		unless balUtilTypes.isArray(commands)
			commands = [commands]

		# Add tasks
		for command in commands
			tasks.push {command}, (complete) ->
				balUtilModules.exec @command, opts, (args...) ->
					err = args[0] or null
					results.push(args)
					complete(err)

		# Run the tasks synchronously
		tasks.sync()

		# Chain
		@

	# =================================
	# Paths

	# Determine an executable path
	# next(err,execPath)
	determineExecPath: (possibleExecPaths,next) ->
		# Prepare
		pathUtil = require('path')
		execPath = null

		# Group
		tasks = new balUtilFlow.Group (err) ->
			next(err,execPath)

		# Handle
		for possibleExecPath in possibleExecPaths
			continue  unless possibleExecPath
			tasks.push {possibleExecPath}, (complete) ->
				{possibleExecPath} = @

				# Resolve the path as it may be a virtual or relative path
				possibleExecPath = pathUtil.resolve(possibleExecPath)

				# Check if the path exists
				balUtilPaths.exists possibleExecPath, (exists) ->
					# Skip if the path doesn't exist
					return complete()  unless exists

					# Check to see if the path is an executable
					balUtilModules.spawn [possibleExecPath, '--version'], {env:process.env}, (err,stdout,stderr,code,signal) ->
						# Problem
						if err
							complete()

						# Good
						else
							execPath = possibleExecPath
							tasks.exit()

		# Fire the tasks synchronously
		tasks.sync()

		# Chain
		@

	# Get Environment Paths
	getEnvironmentPaths: ->
		# Fetch system include paths
		if balUtilModules.isWindows()
			environmentPaths = process.env.PATH.split(/;/g)
		else
			environmentPaths = process.env.PATH.split(/:/g)

		# Return
		return environmentPaths

	# Get standard exec paths
	getStandardExecPaths: (execName) ->
		# Prepare
		possibleExecPaths = [process.cwd()].concat(balUtilModules.getEnvironmentPaths())
		for value,index in possibleExecPaths
			possibleExecPaths[index] = value.replace(/\/$/,'')

		# Get the possible exec paths
		possibleExecPaths = balUtilFlow.suffixArray("/#{execName}", possibleExecPaths)  if execName

		# Return
		return possibleExecPaths

	# Get an Exec Path
	# next(err,foundPath)
	getExecPath: (execName,next) ->
		# If we are for windows add the paths for .exe as well
		if isWindows and execName.indexOf('.') is -1
			possibleExecPaths = balUtilModules.getStandardExecPaths(execName+'.exe').concat(balUtilModules.getStandardExecPaths(execName))
		else
			possibleExecPaths = balUtilModules.getStandardExecPaths(execName)

		# Forward onto determineExecPath
		# Which will determine which path it is out of the possible paths
		balUtilModules.determineExecPath(possibleExecPaths, next)

		# Chain
		@

	# Get Home Path
	# Based upon home function from: https://github.com/isaacs/osenv
	# next(err,homePath)
	getHomePath: (next) ->
		# Cached
		if balUtilModules.cachedHomePath?
			next(null,balUtilModules.cachedHomePath)
			return @

		# Fetch
		homePath = process.env.USERPROFILE or process.env.HOME

		# Forward
		homePath or= null
		balUtilModules.cachedHomePath = homePath
		next(null,homePath)

		# Chain
		@

	# Get Tmp Path
	# Based upon tmpdir function from: https://github.com/isaacs/osenv
	# next(err,tmpPath)
	getTmpPath: (next) ->
		# Cached
		if balUtilModules.cachedTmpPath?
			next(null,balUtilModules.cachedTmpPath)
			return @

		# Prepare
		pathUtil = require('path')
		tmpDirName =
			# Windows
			if isWindows
				'temp'
			# Everything else
			else
				'tmp'

		# Determine
		tmpPath = process.env.TMPDIR or process.env.TMP or process.env.TEMP

		# Fallback
		unless tmpPath
			balUtilModules.getHomePath (err,homePath) ->
				return next(err)  if err
				tmpPath = pathUtil.resolve(homePath, tmpDirName)
				# Fallback
				unless tmpPath
					tmpPath =
						# Windows
						if isWindows
							pathUtil.resolve(process.env.windir or 'C:\\Windows', tmpDirName)
						# Everything else
						else
							'/tmp'

		# Forward
		tmpPath or= null
		balUtilModules.cachedTmpPath = tmpPath
		next(null,tmpPath)

		# Chain
		@

	# Get Git Path
	# As `git` is not always available to use, we should check common path locations
	# and if we find one that works, then we should use it
	# next(err,gitPath)
	getGitPath: (next) ->
		# Cached
		if balUtilModules.cachedGitPath?
			next(null,balUtilModules.cachedGitPath)
			return @

		# Prepare
		execName = if isWindows then 'git.exe' else 'git'
		possibleExecPaths =
			[
				process.env.GIT_PATH
				process.env.GITPATH
			]
			.concat(balUtilModules.getStandardExecPaths(execName))
			.concat(
				if isWindows
					[
						"/Program Files (x64)/Git/bin/#{execName}"
						"/Program Files (x86)/Git/bin/#{execName}"
						"/Program Files/Git/bin/#{execName}"
					]
				else
					[
						"/usr/local/bin/#{execName}"
						"/usr/bin/#{execName}"
						"~/bin/#{execName}"  # Rare occasion
					]
			)

		# Determine the right path
		balUtilModules.determineExecPath possibleExecPaths, (err,execPath) ->
			# Cache
			balUtilModules.cachedGitPath = execPath

			# Check
			return next(err)  if err
			return next(new Error('Could not locate git binary'))  unless execPath

			# Forward
			return next(null,execPath)

		# Chain
		@

	# Get Node Path
	# As `node` is not always available to use, we should check common path locations
	# and if we find one that works, then we should use it
	# next(err,nodePath)
	getNodePath: (next) ->
		# Cached
		if balUtilModules.cachedNodePath?
			next(null,balUtilModules.cachedNodePath)
			return @

		# Prepare
		execName = if isWindows then 'node.exe' else 'node'
		possibleExecPaths =
			[
				process.env.NODE_PATH
				process.env.NODEPATH
				(if /node(.exe)?$/.test(process.execPath) then process.execPath else '')
			]
			.concat(balUtilModules.getStandardExecPaths(execName))
			.concat(
				if isWindows
					[
						"/Program Files (x64)/nodejs/#{execName}"
						"/Program Files (x86)/nodejs/#{execName}"
						"/Program Files/nodejs/#{execName}"
					]
				else
					[
						"/usr/local/bin/#{execName}"
						"/usr/bin/#{execName}"
						"~/bin/#{execName}"  # Heroku
					]
			)

		# Determine the right path
		balUtilModules.determineExecPath possibleExecPaths, (err,execPath) ->
			# Cache
			balUtilModules.cachedNodePath = execPath

			# Check
			return next(err)  if err
			return next(new Error('Could not locate node binary'))  unless execPath

			# Forward
			return next(null,execPath)

		# Chain
		@


	# Get Npm Path
	# As `npm` is not always available to use, we should check common path locations
	# and if we find one that works, then we should use it
	# next(err,npmPath)
	getNpmPath: (next) ->
		# Cached
		if balUtilModules.cachedNpmPath?
			next(null,balUtilModules.cachedNpmPath)
			return @

		# Prepare
		execName = if isWindows then 'npm.cmd' else 'npm'
		possibleExecPaths =
			[
				process.env.NPM_PATH
				process.env.NPMPATH
				(if /node(.exe)?$/.test(process.execPath) then process.execPath.replace(/node(.exe)?$/,execName) else '')
			]
			.concat(balUtilModules.getStandardExecPaths(execName))
			.concat(
				if isWindows
					[
						"/Program Files (x64)/nodejs/#{execName}"
						"/Program Files (x86)/nodejs/#{execName}"
						"/Program Files/nodejs/#{execName}"
					]
				else
					[
						"/usr/local/bin/#{execName}"
						"/usr/bin/#{execName}"
						"~/node_modules/.bin/#{execName}" # Heroku
					]
			)

		# Determine the right path
		balUtilModules.determineExecPath possibleExecPaths, (err,execPath) ->
			# Cache
			balUtilModules.cachedNpmPath = execPath

			# Check
			return next(err)  if err
			return next(new Error('Could not locate npm binary'))  unless execPath

			# Forward
			return next(null,execPath)

		# Chain
		@


	# =================================
	# Basic Commands

	# Perform Git Command
	# opts = {gitPath,cwd,output}
	# next(err,stdout,stderr,code,signal)
	gitCommand: (command,opts,next) ->
		# Extract
		[opts,next] = balUtilFlow.extractOptsAndCallback(opts,next)

		# Extract commands
		if balUtilTypes.isString(command)
			command = command.split(' ')
		else unless balUtilTypes.isArray(command)
			return next(new Error('unknown command type'))

		# Part Two of this command
		performSpawn = ->
			# Prefix the command with the gitPath
			command.unshift(opts.gitPath)
			# Spawn command
			balUtilModules.spawn(command, opts, next)

		# Ensure gitPath
		if opts.gitPath
			performSpawn()
		else
			balUtilModules.getGitPath (err,gitPath) ->
				return next(err)  if err
				opts.gitPath = gitPath
				performSpawn()

		# Chain
		@

	# Perform Git Commands
	# opts = {gitPath,cwd,output}
	# next(err,results)
	gitCommands: (commands,opts,next) ->
		# Extract
		[opts,next] = balUtilFlow.extractOptsAndCallback(opts,next)
		results = []

		# Make sure we send back the arguments
		tasks = new balUtilFlow.Group (err) ->
			next(err,results)

		# Prepare tasks
		unless balUtilTypes.isArray(commands)
			commands = [commands]

		# Add tasks
		for command in commands
			tasks.push {command}, (complete) ->
				balUtilModules.gitCommand @command, opts, (args...) ->
					err = args[0] or null
					results.push(args)
					complete(err)

		# Run the tasks synchronously
		tasks.sync()

		# Chain
		@

	# Perform Node Command
	# opts = {nodePath,cwd,output}
	# next(err,stdout,stderr,code,signal)
	nodeCommand: (command,opts,next) ->
		# Extract
		[opts,next] = balUtilFlow.extractOptsAndCallback(opts,next)

		# Extract commands
		if balUtilTypes.isString(command)
			command = command.split(' ')
		else unless balUtilTypes.isArray(command)
			return next(new Error('unknown command type'))

		# Part Two of this command
		performSpawn = ->
			# Prefix the command with the nodePath
			command.unshift(opts.nodePath)
			# Spawn command
			balUtilModules.spawn(command, opts, next)

		# Ensure nodePath
		if opts.nodePath
			performSpawn()
		else
			balUtilModules.getNodePath (err,nodePath) ->
				return next(err)  if err
				opts.nodePath = nodePath
				performSpawn()

		# Chain
		@

	# Perform Noe Commands
	# opts = {gitPath,cwd,output}
	# next(err,results)
	nodeCommands: (commands,opts,next) ->
		# Extract
		[opts,next] = balUtilFlow.extractOptsAndCallback(opts,next)
		results = []

		# Make sure we send back the arguments
		tasks = new balUtilFlow.Group (err) ->
			next(err,results)

		# Prepare tasks
		unless balUtilTypes.isArray(commands)
			commands = [commands]

		# Add tasks
		for command in commands
			tasks.push {command}, (complete) ->
				balUtilModules.nodeCommand @command, opts, (args...) ->
					err = args[0] or null
					results.push(args)
					complete(err)

		# Run the tasks synchronously
		tasks.sync()

		# Chain
		@

	# Perform NPM Command
	# opts = {npmPath,cwd,output}
	# next(err,stdout,stderr,code,signal)
	npmCommand: (command,opts,next) ->
		# Extract
		[opts,next] = balUtilFlow.extractOptsAndCallback(opts,next)

		# Extract commands
		if balUtilTypes.isString(command)
			command = command.split(' ')
		else unless balUtilTypes.isArray(command)
			return next(new Error('unknown command type'))

		# Part Two of this command
		performSpawn = ->
			# Prefix the command with the npmPath
			command.unshift(opts.npmPath)
			# Spawn command
			balUtilModules.spawn(command, opts, next)

		# Ensure npmPath
		if opts.npmPath
			performSpawn()
		else
			balUtilModules.getNpmPath (err,npmPath) ->
				return next(err)  if err
				opts.npmPath = npmPath
				performSpawn()

		# Chain
		@

	# Perform NPM Commands
	# opts = {gitPath,cwd,output}
	# next(err,results)
	npmCommands: (commands,opts,next) ->
		# Extract
		[opts,next] = balUtilFlow.extractOptsAndCallback(opts,next)
		results = []

		# Make sure we send back the arguments
		tasks = new balUtilFlow.Group (err) ->
			next(err,results)

		# Prepare tasks
		unless balUtilTypes.isArray(commands)
			commands = [commands]

		# Add tasks
		for command in commands
			tasks.push {command}, (complete) ->
				balUtilModules.npmCommand @command, opts, (args...) ->
					err = args[0] or null
					results.push(args)
					complete(err)

		# Run the tasks synchronously
		tasks.sync()

		# Chain
		@


	# =================================
	# Special Commands

	# Initialize a Git Repository
	# Requires internet access
	# opts = {path,remote,url,branch,logger,output,gitPath}
	# next(err)
	initGitRepo: (opts,next) ->
		# Extract
		[opts,next] = balUtilFlow.extractOptsAndCallback(opts,next)
		{path,remote,url,branch,logger,output,gitPath} = opts
		remote or= 'origin'
		branch or= 'master'

		# Prepare commands
		commands = [
			['init']
			['remote', 'add', remote, url]
			['fetch', remote]
			['pull', remote, branch]
			['submodule', 'init']
			['submodule', 'update', '--recursive']
		]

		# Perform commands
		logger.log 'debug', "Initializing git repo with url [#{url}] on directory [#{path}]"  if logger
		balUtilModules.gitCommands commands, {gitPath:gitPath,cwd:path,output:output}, (args...) ->
			return next(args...)  if args[0]?
			logger.log 'debug', "Initialized git repo with url [#{url}] on directory [#{path}]"  if logger
			return next(args...)

		# Chain
		@

	# Initialize or Pull a Git Repo
	initOrPullGitRepo: (opts,next) ->
		# Extract
		[opts,next] = balUtilFlow.extractOptsAndCallback(opts,next)
		{path,remote,branch} = opts
		remote or= 'origin'
		branch or= 'master'

		# Check if it exists
		balUtilPaths.ensurePath path, (err,exists) =>
			return complete(err)  if err
			if exists
				opts.cwd = path
				balUtilModules.gitCommand(['pull',remote,branch], opts, next)
			else
				balUtilModules.initGitRepo(opts, next)

		# Chain
		@

	# Init Node Modules
	# with cross platform support
	# supports linux, heroku, osx, windows
	# next(err,results)
	initNodeModules: (opts,next) ->
		# Prepare
		pathUtil = require('path')
		[opts,next] = balUtilFlow.extractOptsAndCallback(opts,next)
		{path,logger,force} = opts
		opts.cwd = path

		# Paths
		packageJsonPath = pathUtil.join(path,'package.json')
		nodeModulesPath = pathUtil.join(path,'node_modules')

		# Part Two of this command
		partTwo = ->
			# If there is no package.json file, then we can't do anything
			balUtilPaths.exists packageJsonPath, (exists) ->
				return next()  unless exists

				# Prepare command
				command = ['install']
				command.push('--force')  if force

				# Execute npm install inside the pugin directory
				logger.log 'debug', "Initializing node modules\non:   #{dirPath}\nwith:",command  if logger
				balUtilModules.npmCommand command, opts, (args...) ->
					return next(args...)  if args[0]?
					logger.log 'debug', "Initialized node modules\non:   #{dirPath}\nwith:",command  if logger
					return next(args...)

		# Check if node_modules already exists
		if force is false
			balUtilPaths.exists nodeModulesPath, (exists) ->
				return next()  if exists
				partTwo()
		else
			partTwo()


		# Chain
		@


# =====================================
# Export

module.exports = balUtilModules