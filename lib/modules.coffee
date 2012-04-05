# Requires
balUtilModules = null
balUtilFlow = require("#{__dirname}/flow.coffee")


# =====================================
# Paths

balUtilModules =

	# =================================
	# Exec

	# Runs multiple commands at the same time
	# And fires the callback once they have all completed
	# callback(err,results) where args are the result of the exec
	spawn: (commands,options,callback) ->
		# Requires
		{spawn,exec} = require('child_process')
		
		# Sync
		results = []
		options or= {}

		# Make sure we send back the arguments
		tasks = new balUtilFlow.Group (err) ->
			return callback.apply(callback,[err,results])

		# Make sure we send back the arguments
		createHandler = (command) ->
			return ->
				# Prepare
				pid = null
				err = null
				result = ''
				errors = ''

				# Spawn
				if typeof command is 'string'
					pid = spawn(command,[],options)
				else
					pid = spawn(command.command,command.args or [],command.options or options)

				# Fetch
				pid.stdout.on 'data', (data) ->
					dataStr = data.toString()
					if options.output
						console.log(dataStr)
					result += dataStr
				pid.stderr.on 'data', (data) ->
					dataStr = data.toString()
					if options.output
						console.log(dataStr)
					errors += dataStr

				# Wait
				pid.on 'exit', (code,signal) ->
					err = null
					err = new Error(errors)  if errors and code is 1
					results.push [errors,result,code,signal]
					tasks.complete(err)
		
		# Prepare tasks
		unless commands instanceof Array
			commands = [commands]
		
		# Add tasks
		for command in commands
			tasks.push createHandler command

		# Run the tasks synchronously
		tasks.sync()

		# Chain
		@


	# Runs multiple commands at the same time
	# And fires the callback once they have all completed
	# callback(err,results) where args are the result of the exec
	exec: (commands,options,callback) ->
		# Requires
		{spawn,exec} = require('child_process')
		
		# Sync
		results = []

		# Make sure we send back the arguments
		tasks = new balUtilFlow.Group (err) ->
			return callback.apply(callback,[err,results])
		
		# Make sure we send back the arguments
		createHandler = (command) ->
			return ->
				exec command, options, (args...) ->
					# Prepare
					err = args[0] or null
					
					# Push args to result list
					results.push args

					# Complete the task
					tasks.complete(err)
			
		# Prepare tasks
		unless commands instanceof Array
			commands = [commands]
		
		# Add tasks
		for command in commands
			tasks.push createHandler command

		# Run the tasks synchronously
		tasks.sync()

		# Chain
		@

	
	# Initialise git submodules
	# next(err,results)
	initGitSubmodules: (dirPath,next) ->
		# Create the child process
		child = balUtilModules.exec(
			# Commands
			[
				'git submodule init'
				'git submodule update'
				'git submodule foreach --recursive "git init"'
				'git submodule foreach --recursive "git checkout master"'
				'git submodule foreach --recursive "git submodule init"'
				'git submodule foreach --recursive "git submodule update"'
			]
			
			# Options
			{
				cwd: dirPath
			}

			# Next
			next
		)

		# Return child process
		return child
	
	
	# Initialise node modules
	# next(err,results)
	initNodeModules: (dirPath,next) ->
		# Create the child process
		child = balUtilModules.exec(
			# Commands
			[
				'npm install'
			]
			
			# Options
			{
				cwd: dirPath
			}

			# Next
			next
		)

		# Return child process
		return child
	

	# Git Pull
	# next(err,results)
	gitPull: (dirPath,url,next) ->
		# Create the child process
		child = exec(
			# Commands
			[
				"git init"
				"git remote add origin #{url}"
				"git pull origin master"
			]
			
			# Options
			{
				cwd: dirPath
			}

			# Next
			next
		)

		# Return the child process
		return child


# =====================================
# Export

module.exports = balUtilModules