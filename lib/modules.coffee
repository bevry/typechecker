# Requires
balUtilModules = null
balUtilGroups = require("#{__dirname}/groups.coffee")


# =====================================
# Paths

balUtilModules =

	# =================================
	# Exec

	# Runs multiple commands at the same time
	# And fires the callback once they have all completed
	# callback(err,args...) where args are the result of the exec
	exec: (commands,options,callback) ->
		# Requires
		child_process = require('child_process')
		
		# Sync
		mode = options.mode or null
		results = []

		# Make sure we send back the arguments
		tasks = new balUtilGroups.Group ->
			if mode is 'single'
				callback.apply(callback,results[0])
			else
				callback.apply(callback,[results])
		
		# Make sure we send back the arguments
		createHandler = (command) ->
			return -> child_process.exec command, options, (args...) ->
				err = args[0] or null
				
				# Push args to result list
				results.push args

				# Complete the task
				tasks.complete(err)
		
		# Prepare tasks
		if commands instanceof Array
			mode or= 'multiple'
		else
			mode or= 'single'
			commands = [commands]
		
		# Add tasks
		for command in commands
			tasks.push createHandler command

		# Run the tasks synchronously
		tasks.sync()

		# Chain
		@

	
	# Initialise git submodules
	# next(err,stdout,stderr)
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
	# next(err,stdout,stderr)
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
	# next(err,stdout,stderr)
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