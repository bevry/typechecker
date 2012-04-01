# Requires
fs = require('fs')
debug = false

# BalUtil
balUtil = {}
balUtilCompare = require("#{__dirname}/compare.coffee")
balUtilEvents = require("#{__dirname}/events.coffee")
balUtilFlow = require("#{__dirname}/flow.coffee")
balUtilModules = require("#{__dirname}/modules.coffee")
balUtilPaths = require("#{__dirname}/paths.coffee")
balUtilTypes = require("#{__dirname}/types.coffee")
subpackages = [
	balUtilCompare
	balUtilEvents
	balUtilFlow
	balUtilModules
	balUtilPaths
	balUtilTypes
]

# Merge in the sub-packages
for subpackage in subpackages
	for own key, value of subpackage
		balUtil[key] = value

# Export
module.exports = balUtil