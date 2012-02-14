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
	# callback(err,results) where args are the result of the exec
	exec: (commands,options,callback) ->
		# Requires
		child_process = require('child_process')
		
		# Sync
		mode = options.mode or null
		results = []

		# Make sure we send back the arguments
		tasks = new balUtilGroups.Group (err) ->
			return callback.apply(callback,[err,results])
		
		# Make sure we send back the arguments
		createHandler = (command) ->
			return -> child_process.exec command, options, (args...) ->
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