# Requires
balUtilModules = null
balUtilFlow = require(__dirname+'/flow')


# =====================================
# Paths

balUtilModules =

	# =================================
	# Executing

	# Runs multiple commands at the same time
	# And fires the callback once they have all completed
	# callback(err,results) where args are the result of the exec
	spawn: (commands,options,callback) ->
		# Prepare
		[options,callback] = balUtilFlow.extractOptsAndCallback(options,callback)
		{spawn} = require('child_process')

		# Sync
		results = []
		options or= {}

		# Make sure we send back the arguments
		tasks = new balUtilFlow.Group (err) ->
			return callback.apply(callback,[err,results])

		# Prepare tasks
		unless commands instanceof Array
			commands = [commands]

		# Add tasks
		balUtilFlow.each commands, (command) -> tasks.push (complete) ->
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
				pid = spawn(command[0], command.slice(1), options)
			else
				pid = spawn(command.command, command.args or [], command.options or options)

			# Fetch
			pid.stdout.on 'data', (data) ->
				dataStr = data.toString()
				if options.output
					process.stdout.write(dataStr)
				stdout += dataStr
			pid.stderr.on 'data', (data) ->
				dataStr = data.toString()
				if options.output
					process.stderr.write(dataStr)
				stderr += dataStr

			# Wait
			pid.on 'exit', (code, signal) ->
				err = null
				if code is 1
					err = new Error(stderr or 'exited with failure code')
				results.push [err,stdout,stderr,code,signal]
				complete(err)

		# Run the tasks synchronously
		tasks.sync()

		# Chain
		@


	# Runs multiple commands at the same time
	# And fires the callback once they have all completed
	# callback(err,results) where args are the result of the exec
	exec: (commands,options,callback) ->
		# Prepare
		[options,callback] = balUtilFlow.extractOptsAndCallback(options,callback)
		{exec} = require('child_process')

		# Sync
		results = []

		# Make sure we send back the arguments
		tasks = new balUtilFlow.Group (err) ->
			return callback.apply(callback,[err,results])

		# Prepare tasks
		unless commands instanceof Array
			commands = [commands]

		# Add tasks
		balUtilFlow.each commands, (command) -> tasks.push (complete) ->
			exec command, options, (args...) ->
				# Prepare
				err = args[0] or null

				# Push args to result list
				results.push args

				# Complete the task
				complete(err)

		# Run the tasks synchronously
		tasks.sync()

		# Chain
		@



	# =================================
	# Git

	# Get git path
	getGitPath: (next) ->
		# Prepare
		pathUtil = require('path')
		foundGitPath = null
		possibleGitPaths =
			# Windows
			if process.platform.indexOf('win') isnt -1
				[
					'git'
					pathUtil.join('%ProgramFiles%','Git','bin','git')
					pathUtil.join('%ProgramFiles(x86)%','Git','bin','git')
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
		balUtilFlow.each possibleGitPaths, (possibleGitPath) ->
			tasks.push (complete) ->
				balUtilModules.spawn [[possibleGitPath, '--version']], (err,results) ->
					unless err
						foundGitPath = possibleGitPath
						tasks.exit()
					else
						complete()

		# Fire the tasks synchronously
		tasks.sync()

		# Chain
		@

	# Initialize a Git Repository
	# Requires internet access
	# next(err)
	initGitRepo: (opts={}) ->
		# Extract
		{path,remote,url,branch,gitPath,logger,output,next} = opts
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
		balUtilModules.spawn commands, {cwd:path,output:output}, (err,results) ->
			# Check
			return next(err,results)  if err

			# Complete
			logger.log 'debug', "Initialized git repo with url [#{url}] on directory [#{path}]"  if logger
			return next(err,results)


	# =================================
	# Node

	# Init Node Modules
	# with cross platform support
	# supports linux, heroku, osx, windows
	# next(err,results)
	initNodeModules: (opts={}) ->
		# Requires
		pathUtil = require('path')

		# Extract
		{path,nodePath,npmPath,force,logger,output,next} = opts
		npmPath or= 'npm'  # default to global npm installation

		# Paths
		packageJsonPath = pathUtil.join(path,'package.json')
		nodeModulesPath = pathUtil.join(path,'node_modules')

		# Check if node modules already exists
		if force is false and pathUtil.existsSync(nodeModulesPath)
			return next()

		# If there is no package.json file, then we can't do anything
		unless pathUtil.existsSync(packageJsonPath)
			return next()

		# Use npm with node
		if nodePath
			command =
				command: nodePath
				args: [npmPath, 'install']
		# Use npm standalone
		else
			command =
				command: npmPath
				args: ['install']

		# Execute npm install inside the pugin directory
		logger.log 'debug', "Initializing node modules\non:   #{dirPath}\nwith:",command  if logger
		balUtilModules.spawn command, {cwd:path,output}, (err,results) ->
			if logger
				logger.log 'debug', "Initialized node modules\non:   #{dirPath}\nwith:",command  if logger
			return next(err,results)

		# Chain
		@


# =====================================
# Export

module.exports = balUtilModules