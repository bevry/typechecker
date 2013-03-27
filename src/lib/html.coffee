# Import
balUtilFlow = require('./flow')


# =====================================
# HTML

balUtilHTML =

	# Extract Argument
	getAttribute: (attributes,attribute) ->
		regex = new RegExp("""(#{attribute})\\s*=\\s*('[^']+'|\\"[^\\"]+\\"|[^'\\"\\s]\\S*)""",'ig')
		value = null
		while match = regex.exec(attributes)
			value = match[2].trim().replace(/(^['"]\s*|\s*['"]$)/g, '')
		return value

	# Detect Indentation
	detectIndentation: (source) ->
		result = /\n([ \t]*)\S/m.exec(source)
		indentation = result?[1] or ''
		return indentation

	# Remove Indentation
	removeIndentation: (source) ->
		indentation = balUtilHTML.detectIndentation(source)
		regexString = indentation.replace(/\t/g,'\\t')
		regex = new RegExp("""^#{regexString}""",'gm')
		result = source.replace(regex,'').trim()
		return result

	# Replace Element
	# replaceElementCallback(outerHTML, element, attributes, innerHTML)
	# returns the replace result
	replaceElement: (args...) ->
		# Extract
		if args.length is 1
			{html, element, removeIndentation, replace} = args[0]
		else
			[html, element, replace] = args

		# Replace
		regex = new RegExp("""<(#{element}(?:\\:[-:_a-z0-9]+)?)(\\s+[^>]+)?>([\\s\\S]+?)<\\/\\1>""",'ig')
		result = html.replace regex, (outerHTML, element, attributes, innerHTML) ->
			# Remove the indentation from the innerHTML
			innerHTML = balUtilHTML.removeIndentation(innerHTML)  if removeIndentation isnt false
			# Fetch the result
			return replace(outerHTML, element, attributes, innerHTML)

		# Return
		return result

	# Replace Element Async
	# replaceElementCallback(outerHTML, element, attributes, innerHTML, replaceElementCompleteCallback), replaceElementCompleteCallback(err,replaceElementResult)
	# next(err,result)
	replaceElementAsync: (args...) ->
		# Extract
		if args.length is 1
			{html, element, removeIndentation, replace, next} = args[0]
		else
			[html, element, replace, next] = args

		# Prepare
		tasks = new balUtilFlow.Group (err) ->
			return next(err)  if err
			return next(null,result)

		# Replace
		result = balUtilHTML.replaceElement(
			html: html
			element: element
			removeIndentation: removeIndentation
			replace: (outerHTML, element, attributes, innerHTML) ->
				# Generate a temporary random number to replace the text with in the meantime
				random = Math.random()

				# Push the actual replace task
				tasks.push (complete) ->
					replace outerHTML, element, attributes, innerHTML, (err,replaceElementResult) ->
						return complete(err)  if err
						result = result.replace(random,replaceElementResult)
						return complete()

				# Return the random to the replace
				return random
		)

		# Run the tasks synchronously
		tasks.sync()

		# Chain
		@


# =====================================
# Export

module.exports = balUtilHTML