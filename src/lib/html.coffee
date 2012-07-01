# Requires
balUtilFlow = require?(__dirname+'/flow') or @balUtilFlow

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
	# replaceElementCallback(outerHTML, elementNameMatched, attributes, innerHTML)
	# returns the replace result
	replaceElement: (source, elementNameMatcher, replaceElementCallback) ->
		regex = new RegExp("""<(#{elementNameMatcher}(?:\\:[-:_a-z0-9]+)?)([^>]*)>([\\s\\S]+?)<\\/\\1>""",'ig')
		result = source.replace regex, (outerHTML, elementNameMatched, attributes, innerHTML) ->
			# Remove the indentation from the innerHTML
			innerHTML = balUtilHTML.removeIndentation(innerHTML)
			# Fetch the result
			return replaceElementCallback(outerHTML, elementNameMatched, attributes, innerHTML)
		return result

	# Replace Element Async
	# replaceElementCallback(outerHTML, elementNameMatched, attributes, innerHTML, replaceElementCompleteCallback), replaceElementCompleteCallback(err,replaceElementResult)
	# next(err,result)
	replaceElementAsync: (source, elementNameMatcher, replaceElementCallback, next) ->
		# Prepare
		tasks = new balUtilFlow.Group (err) ->
			return next(err)  if err
			return next(null,result)

		# Replace
		result = balUtilHTML.replaceElement source, elementNameMatcher, (outerHTML, elementNameMatched, attributes, innerHTML) ->
			# Generate a temporary random number to replace the text with in the meantime
			random = Math.random()

			# Push the actual replace task
			tasks.push (complete) ->
				replaceElementCallback outerHTML, elementNameMatched, attributes, innerHTML, (err,replaceElementResult) ->
					return complete(err)  if err
					result = result.replace(random,replaceElementResult)
					return complete()

			# Return the random to the replace
			return random

		# Run the tasks synchronously
		tasks.sync()

		# Chain
		@

# =====================================
# Export
# for node.js and browsers

if module? then (module.exports = balUtilHTML) else (@balUtilHTML = balUtilHTML)