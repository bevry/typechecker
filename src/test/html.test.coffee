# Requires
assert = require?('assert') or @assert
joe = require?('joe') or @joe
balUtil = require?(__dirname+'/../lib/balutil') or @balUtil


# =====================================
# Tests

wait = (delay,fn) -> setTimeout(fn,delay)

# -------------------------------------
# Flow

joe.suite 'html', (suite,test) ->

	test 'replaceElement', ->
		# Prepare
		source = """
			start
			<text>
				a
					b
				c
			</text>
			middle
			<text>
				one
					two
				three
			</text>
			finish
			"""
		expected = """
			start
			A
				B
			C
			middle
			ONE
				TWO
			THREE
			finish
			"""
		replaceElementCallback = (outerHTML, elementNameMatched, attributes, innerHTML) ->
			return innerHTML.toUpperCase()
		actual = balUtil.replaceElement(source, "text", replaceElementCallback)
		assert.equal(expected, actual)

	test 'replaceElementAsync', (done) ->
		# Prepare
		source = """
			start
			<text>
				a
					b
				c
			</text>
			middle
			<text>
				one
					two
				three
			</text>
			finish
			"""
		expected = """
			start
			A
				B
			C
			middle
			ONE
				TWO
			THREE
			finish
			"""
		replaceElementCallback = (outerHTML, elementNameMatched, attributes, innerHTML, callback) ->
			balUtil.wait 1000, ->
				callback null, innerHTML.toUpperCase()
		balUtil.replaceElementAsync source, "text", replaceElementCallback, (err,actual) ->
			return done(err)  if err
			assert.equal(expected, actual)
			done()
