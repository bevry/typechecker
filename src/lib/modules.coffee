# Requires
balUtilModules = null
balUtilFlow = require(__dirname+'/flow')
balUtilPaths = require(__dirname+'/paths')
balUtilTypes = require(__dirname+'/types')

# Prepare
isWindows = process? and process.platform.indexOf('win') is 0


# =====================================
# Paths

balUtilModules =

	# =================================
	# Environments

	# Is Windows
	# Returns whether or not we are running on a windows machine
	isWindows: ->
		return isWindows

	# =================================
	# Spawn

	# Spawn
	# Wrapper around node's spawn command for a cleaner and more powerful API
	# next(err,stdout,stderr,code,signal)
	spawn: (command,opts,next) ->
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
			dataStr = data.toString()
			if opts.output
				process.stdout.write(dataStr)
			stdout += dataStr
		pid.stderr.on 'data', (data) ->
			dataStr = data.toString()
			if opts.output
				process.stderr.write(dataStr)
			stderr += dataStr

		# Wait
		pid.on 'exit', (code,signal) ->
			err = null
			if code isnt 0
				err = new Error(stderr or 'exited with a non-zero status code')
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
				balUtilModules.spawn @command, opts, (args...) ->
					err = args[0] or null
					results.push(args)
					complete(err)

		# Run the tasks synchronously
		tasks.sync()

		# Chain
		@


	# =================================
	# Exec

	# Exec
	# Wrapper around node's exec command for a cleaner and more powerful API
	# next(err,stdout,stderr)
	exec: (command,opts,next) ->
		# Prepare
		{exec} = require('child_process')
		[opts,next] = balUtilFlow.extractOptsAndCallback(opts,next)

		# Execute command
		exec command, opts, (err,stdout,stderr) ->
			# Complete the task
			next(err,stdout,stderr)

		# Chain
		@

	# Exec Multiple
	# next(err,results), results = [result...], result = [err,stdout,stderr]
	execMultiple: (commands,opts,next) ->
		# Prepare
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
	# next(err,foundPath)
	determineExecPath: (possiblePaths,next) ->
		# Prepare
		foundPath = null

		# Group
		tasks = new balUtilFlow.Group (err) ->
			next(err,foundPath)

		# Handle
		for possiblePath in possiblePaths
			continue  unless possiblePath
			tasks.push {possiblePath}, (complete) ->
				{possiblePath} = @
				balUtilModules.spawn [possiblePath, '--version'], (err,stdout,stderr,code,signal) ->
					# Problem
					if err
						complete()
					# Good
					else
						foundPath = possiblePath
						tasks.exit()

		# Fire the tasks synchronously
		tasks.sync()

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

		# Prepare
		pathUtil = require('path')

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
		pathUtil = require('path')
		possiblePaths =
			# Windows
			if isWindows
				[
					process.env.GIT_PATH
					process.env.GITPATH
					'git'
					pathUtil.resolve('/Program Files (x64)/Git/bin/git.exe')
					pathUtil.resolve('/Program Files (x86)/Git/bin/git.exe')
					pathUtil.resolve('/Program Files/Git/bin/git.exe')
				]
			# Everything else
			else
				[
					process.env.GIT_PATH
					process.env.GITPATH
					'git'
					'/usr/local/bin/git'
					'/usr/bin/git'
				]

		# Determine the right path
		balUtilModules.determineExecPath possiblePaths, (err,gitPath) ->
			# Forward
			balUtilModules.cachedGitPath = gitPath
			next(err,gitPath)

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

		# Fetch
		pathUtil = require('path')
		possiblePaths =
			# Windows
			if isWindows
				[
					process.env.NODE_PATH
					process.env.NODEPATH
					(if /node(.exe)?$/.test(process.execPath) then process.execPath else '')
					'node'
					pathUtil.resolve('/Program Files (x64)/nodejs/node.exe')
					pathUtil.resolve('/Program Files (x86)/nodejs/node.exe')
					pathUtil.resolve('/Program Files/nodejs/node.exe')
				]
			# Everything else
			else
				[
					process.env.NODE_PATH
					process.env.NODEPATH
					(if /node$/.test(process.execPath) then process.execPath else '')
					'node'
					'/usr/local/bin/node'
					'/usr/bin/node'
					'~/bin/node'  # Heroku
				]

		# Determine the right path
		balUtilModules.determineExecPath possiblePaths, (err,nodePath) ->
			# Forward
			balUtilModules.cachedNodePath = nodePath
			next(err,nodePath)

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

		# Fetch
		pathUtil = require('path')
		possiblePaths =
			# Windows
			if isWindows
				[
					process.env.NPM_PATH
					process.env.NPMPATH
					(if /node(.exe)?$/.test(process.execPath) then process.execPath.replace(/node(.exe)?$/,'npm.cmd') else '')
					'npm'  # .cmd extension not needed here, as windows will resolve it, for absolute paths, we need the .cmd extension however
					pathUtil.resolve('/Program Files (x64)/nodejs/npm.cmd')
					pathUtil.resolve('/Program Files (x86)/nodejs/npm.cmd')
					pathUtil.resolve('/Program Files/nodejs/npm.cmd')
				]
			# Everything else
			else
				[
					process.env.NPM_PATH
					process.env.NPMPATH
					(if /node$/.test(process.execPath) then process.execPath.replace(/node$/,'npm') else '')
					'npm'
					'/usr/local/bin/npm'
					'/usr/bin/npm'
					'~/node_modules/.bin/npm'  # Heroku
				]

		# Determine the right path
		balUtilModules.determineExecPath possiblePaths, (err,npmPath) ->
			# Forward
			balUtilModules.cachedNpmPath = npmPath
			next(err,npmPath)

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