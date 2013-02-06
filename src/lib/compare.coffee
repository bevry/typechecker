# Requires
balUtilCompare = null
balUtilPaths = require('./paths')


# =====================================
# Compare

balUtilCompare =

	# Version Compare
	# http://phpjs.org/functions/version_compare
	# MIT Licensed http://phpjs.org/pages/license
	versionCompare: (v1,operator,v2) ->
		i = x = compare = 0
		vm =
			'dev': -6
			'alpha': -5
			'a': -5
			'beta': -4
			'b': -4
			'RC': -3
			'rc': -3
			'#': -2
			'p': -1
			'pl': -1

		prepVersion = (v) ->
			v = ('' + v).replace(/[_\-+]/g, '.')
			v = v.replace(/([^.\d]+)/g, '.$1.').replace(/\.{2,}/g, '.')
			if !v.length
				[-8]
			else
				v.split('.')

		numVersion = (v) ->
			if !v
				0
			else
				if isNaN(v)
					vm[v] or -7
				else
					parseInt(v, 10)

		v1 = prepVersion(v1)
		v2 = prepVersion(v2)
		x = Math.max(v1.length, v2.length)

		for i in [0..x]
			if (v1[i] == v2[i])
				continue

			v1[i] = numVersion(v1[i])
			v2[i] = numVersion(v2[i])

			if (v1[i] < v2[i])
				compare = -1
				break
			else if v1[i] > v2[i]
				compare = 1
				break

		if !operator
			return compare

		result =
			switch operator
				when '>', 'gt'
					compare > 0
				when '>=', 'ge'
					compare >= 0
				when '<=', 'le'
					compare <= 0
				when '==', '=', 'eq', 'is'
					compare == 0
				when '<>', '!=', 'ne', 'isnt'
					compare != 0
				when '', '<', 'lt'
					compare < 0
				else
					null

		# Return result
		result


	# Compare Package
	packageCompare: ({local,remote,newVersionCallback,sameVersionCallback,oldVersionCallback,errorCallback}) ->
		# Prepare
		details = {}

		# Handler
		runCompare = ->
			if balUtilCompare.versionCompare(details.local.version, '<', details.remote.version)
				newVersionCallback?(details)
			else if balUtilCompare.versionCompare(details.local.version, '==', details.remote.version)
				sameVersionCallback?(details)
			else if balUtilCompare.versionCompare(details.local.version, '>', details.remote.version)
				oldVersionCallback?(details)

		# Read local
		balUtilPaths.readPath local, (err,data) ->
			return errorCallback?(err,data)  if err
			try
				dataStr = data.toString()
				details.local = JSON.parse(dataStr)
			catch err
				return errorCallback?(err,data)
			# Read remote
			balUtilPaths.readPath remote, (err,data) ->
				return errorCallback?(err,data)  if err
				try
					dataStr = data.toString()
					details.remote = JSON.parse(dataStr)
				catch err
					return errorCallback?(err,data)
				# Compare
				runCompare()

		# Chain
		@


# =====================================
# Export

module.exports = balUtilCompare