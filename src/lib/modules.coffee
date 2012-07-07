# Requires
balUtilModules = null
balUtilFlow = require(__dirname+'/flow')
balUtilPaths = require(__dirname+'/paths')


# =====================================
# Paths

balUtilModules =

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
		if typeof command is 'string'
			command = command.split(' ')

		# Execute command
		if command instanceof Array
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
		unless commands instanceof Array
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
	exec: (commands,opts,next) ->
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
		unless commands instanceof Array
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

	# Get Git Path
	# As `git` is not always available to use, we should check common path locations
	# and if we find one that works, then we should use it
	# next(err,gitPath)
	getGitPath: (next) ->
		# Prepare
		pathUtil = require('path')
		foundGitPath = null
		possibleGitPaths =
			# Windows
			if process.platform.indexOf('win') isnt -1
				[
					'git'
					pathUtil.resolve('/Program Files (x64)/Git/bin/git.exe')
					pathUtil.resolve('/Program Files (x86)/Git/bin/git.exe')
					pathUtil.resolve('/Program Files/Git/bin/git.exe')
				]
			# Everything else
			else
				[
					'git'
					'/usr/local/bin/git'
					'/usr/bin/git'
				]

		# Group
		tasks = new balUtilFlow.Group (err) ->
			next(err,foundGitPath)

		# Handle
		for possibleGitPath in possibleGitPaths
			tasks.push {possibleGitPath}, (complete) ->
				possibleGitPath = @possibleGitPath
				balUtilModules.spawn [possibleGitPath, '--version'], (err,stdout,stderr,code,signal) ->
					# Problem
					if err
						complete()
					# Good
					else
						foundGitPath = possibleGitPath
						tasks.exit()

		# Fire the tasks synchronously
		tasks.sync()

		# Chain
		@

	# Get Node Path
	# As `node` is not always available to use, we should check common path locations
	# and if we find one that works, then we should use it
	# next(err,nodePath)
	getNodePath: (next) ->
		# Fetch
		nodePath = null
		possibleNodePath = if /node$/.test(process.execPath) then process.execPath else 'node'

		# Test
		balUtilModules.spawn [possibleNodePath, '--version'], (err,stdout,stderr,code,signal) ->
			# Problem
			if err
				# do nothing
			# Good
			else
				nodePath = possibleNodePath

			# Forward
			next(null,nodePath)

		# Chain
		@


	# =================================
	# Git

	# Initialize a Git Repository
	# Requires internet access
	# next(err)
	initGitRepo: (opts,next) ->
		# Extract
		[opts,next] = balUtilFlow.extractOptsAndCallback(opts,next)
		{path,remote,url,branch,gitPath,logger,output} = opts
		gitPath or= 'git'  # default to global git installation

		# Initialise
		commands = [
			command: gitPath
			args: ['init']
		,
			command: gitPath
			args: ['remote', 'add', remote, url]
		,
			command: gitPath
			args: ['fetch', remote]
		,
			command: gitPath
			args: ['pull', remote, branch]
		,
			command: gitPath
			args: ['submodule', 'init']
		,
			command: gitPath
			args: ['submodule', 'update', '--recursive']
		]
		logger.log 'debug', "Initializing git repo with url [#{url}] on directory [#{path}]"  if logger
		balUtilModules.spawnMultiple commands, {cwd:path,output:output}, (args...) ->
			return next(args...)  if args[0]?
			logger.log 'debug', "Initialized git repo with url [#{url}] on directory [#{path}]"  if logger
			return next(args...)


	# =================================
	# Node

	# Perform NPM Command
	# next(err,stdout,stderr,code,signal)
	npmCommand: (command,opts,next) ->
		# Extract
		[opts,next] = balUtilFlow.extractOptsAndCallback(opts,next)
		{nodePath,npmPath,cwd,output} = opts
		npmPath or= 'npm'  # default to global npm installation

		# Exttract commands
		if typeof command is 'string'
			command = command.split(' ')
		else unless command instanceof Array
			return next(new Error('unknown command type'))

		# Prefix the node and npm paths
		command.unshift(npmPath)
		command.unshift(nodePath)  if nodePath

		# Execute npm install inside the pugin directory
		balUtilModules.spawn(command, {cwd,output}, next)


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

		# Check if node modules already exists
		if force is false and balUtilPaths.existsSync(nodeModulesPath)
			return next()

		# If there is no package.json file, then we can't do anything
		unless balUtilPaths.existsSync(packageJsonPath)
			return next()

		# Prepare command
		command = ['install']
		if force
			command.push('--force')

		# Execute npm install inside the pugin directory
		logger.log 'debug', "Initializing node modules\non:   #{dirPath}\nwith:",command  if logger
		balUtilModules.npmCommand command, opts, (args...) ->
			return next(args...)  if args[0]?
			logger.log 'debug', "Initialized node modules\non:   #{dirPath}\nwith:",command  if logger
			return next(args...)

		# Chain
		@


# =====================================
# Export

module.exports = balUtilModules