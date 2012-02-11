# Requires
assert = require 'assert'
EventSystem = require(__dirname+'/../lib/balutil.coffee').EventSystem
debug = false


# =====================================
# Configuration

class Person extends EventSystem
	###
	A person can eat while they drink, but they can't drink while they eat
	This has come from the fact that if you have food in your mouth, you can still drink things
	Whereas if you have drink in your mouth, then put food in your mouth, the drink goes everywhere
	###

	# Eat something
	eat: (something,next) ->
		console.log "#{something}: started food"  if debug

		# Start eating
		console.log "#{something}: start eating"  if debug
		@start 'eating', (err) =>
			# Eating
			console.log "#{something}: eating"  if debug
			return next?(err)  if err

			# Finish eating after 2 seconds
			setTimeout(=>
				# Finished eating
				console.log "#{something}: swallowed food"  if debug
			
				# Perform our callback
				next?(null,something)

				# Clean up
				console.log "#{something}: start finish"  if debug
				@finished 'eating', (err) ->
					# Finished drinking
					console.log "#{something}: finished food"  if debug
					return next?(err)  if err

			,2*1000)
		
	
	# Drink something
	drink: (something,next) ->
		console.log "#{something}: started drink"  if debug

		# Prevent eating
		console.log "#{something}: blocking eating"  if debug
		@block 'eating', (err) =>
			# Eating blocked
			console.log "#{something}: blocked eating"  if debug
			return next?(err)  if err
				
			# Start drinking
			console.log "#{something}: start drinking"  if debug
			@start 'drinking', (err) =>
				# Drinking
				console.log "#{something}: drinking"  if debug
				return next?(err)  if err

				# Finish drinking after 1 seconds
				setTimeout(=>
					console.log "#{something}: swallowed drink"  if debug

					# Perform our callback
					next?(null,something)
			
					# Clean up
					console.log "#{something}: start finish"  if debug
					@finished 'drinking', (err) =>
						# Finished drinking
						console.log "#{something}: finished drink"  if debug
						throw err  if err
						
						# Resume eating
						console.log "#{something}: unblocking eating"  if debug
						@unblock 'eating', (err) =>
							console.log "#{something}: unblocked eating"  if debug
							throw err  if err

				,1*1000)
		

# =====================================
# Tests

describe 'EventSystem', ->

	it 'should work as expected', (done) ->
		# Prepare
		@timeout(15000)
		foods = ['apple','orange','grape']
		drinks = ['coke','fanta','water']
		joe = new Person()

		# Completion handlers
		foodsAte = []
		drinksDrunk = []
		joeTriedToDrinkThenEat = false

		# Track the order of what joe ate 
		eating = false
		drinking = false
		joe.on 'eating:locked', ->
			console.log 'eating:locked'  if debug
		joe.on 'eating:unlocked', ->
			console.log 'eating:unlocked'  if debug
		joe.on 'eating:started', ->
			console.log 'eating:started'  if debug
			if drinking is true
				console.log 'joe just tried to eat then drink'  if debug
				joeTriedToDrinkThenEat = true
			eating = true
		joe.on 'eating:finished', ->
			console.log 'eating:finished'  if debug
			eating = false
		
		joe.on 'drinking:locked', ->
			console.log 'drinking:locked'  if debug
		joe.on 'drinking:unlocked', ->
			console.log 'drinking:unlocked'  if debug
		joe.on 'drinking:started', ->
			console.log 'drinking:started'  if debug
			drinking = true
		joe.on 'drinking:finished', ->
			console.log 'drinking:finished'  if debug
			drinking = false

		# Track what joe ate
		ateAFood = (err,something) ->
			throw err  if err
			foodsAte.push something
			console.log "completely finished eating #{something} - #{foodsAte.length}/#{foods.length}"  if debug
		drankADrink = (err,something) ->
			throw err  if err
			drinksDrunk.push something
			console.log "completely finished drinking #{something} - #{drinksDrunk.length}/#{drinks.length}"  if debug
		
		# Stuff joe full of stuff
		joe.eat(food,ateAFood)  for food in foods
		joe.drink(drink,drankADrink)  for drink in drinks

		# Async
		setTimeout(
			->
				assert.equal(foods.length, foodsAte.length, 'joe ate all his foods')
				assert.equal(drinks.length, drinksDrunk.length, 'joe ate all his drinks')
				assert.equal(false, joeTriedToDrinkThenEat, 'joe tried to drink then eat, when he shouldn\'t have')
				done()
			,14000
		)
