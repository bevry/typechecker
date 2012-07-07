# BalUtil
balUtil = {}
balUtilCompare = require(__dirname+'/compare')
balUtilEvents = require(__dirname+'/events')
balUtilFlow = require(__dirname+'/flow')
balUtilHTML = require(__dirname+'/html')
balUtilModules = require(__dirname+'/modules')
balUtilPaths = require(__dirname+'/paths')
balUtilTypes = require(__dirname+'/types')
subpackages = [
	balUtilCompare
	balUtilEvents
	balUtilFlow
	balUtilHTML
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