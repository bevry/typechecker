# BalUtil
balUtil = {}
balUtilCompare = require('./compare.js')
balUtilEvents = require('./events')
balUtilFlow = require('./flow')
balUtilHTML = require('./html')
balUtilModules = require('./modules')
balUtilPaths = require('./paths')
balUtilTypes = require('./types')
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