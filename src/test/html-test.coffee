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
			breakfast
			<title>blah</title>
			brunch
			<t>
				a
					b
				c
			</t>
			lunch
			<text>
				one
					two
				three
			</text>
			dinner
			"""
		expected = """
			breakfast
			<title>blah</title>
			brunch
			A
				B
			C
			lunch
			ONE
				TWO
			THREE
			dinner
			"""
		replaceElementCallback = (outerHTML, elementNameMatched, attributes, innerHTML) ->
			return innerHTML.toUpperCase()
		actual = balUtil.replaceElement(source, "t(?:ext)?", replaceElementCallback)
		assert.equal(expected, actual)

	test 'replaceElementAsync', (done) ->
		# Prepare
		source = """
			breakfast
			<title>blah</title>
			brunch
			<t>
				a
					b
				c
			</t>
			lunch
			<text>
				one
					two
				three
			</text>
			dinner
			"""
		expected = """
			breakfast
			<title>blah</title>
			brunch
			A
				B
			C
			lunch
			ONE
				TWO
			THREE
			dinner
			"""
		replaceElementCallback = (outerHTML, elementNameMatched, attributes, innerHTML, callback) ->
			balUtil.wait 1000, ->
				callback null, innerHTML.toUpperCase()
		balUtil.replaceElementAsync source, "t(?:ext)?", replaceElementCallback, (err,actual) ->
			return done(err)  if err
			assert.equal(expected, actual)
			done()
