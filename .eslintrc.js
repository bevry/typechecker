// 2017 April 17
// https://github.com/bevry/base
// http://eslint.org
// This code must be able to run on Node 0.10
/* eslint no-warning-comments: 0 */
'use strict'

const config = {
	extends: ['eslint:recommended'],
	plugins: [],
	parserOptions: { ecmaFeatures: {} },
	env: {},
	rules: {
		// ----------------------------
		// Problems with these rules
		// If we can figure out how to enable the following, that would be great

		// Two spaces after one line if or else:
		// if ( blah )  return
		// Insead of one space:
		// if ( blah ) return

		// No spaces on embedded function:
		// .forEach(function(key, value){
		// instead of:
		// .forEach(function (key, value) {

		// Else and catch statements on the same line as closing brace:
		// } else {
		// } catch (e) {
		// instead of:
		// }
		// else {


		// --------------------------------------
		// Possible Errors
		// The following rules point out areas where you might have made mistakes.

		// Don't allow assignments in conditional statements (if, while, etc.)
		'no-cond-assign': ["error", 'always'],

		// Warn but don't error about console statements
		'no-console': "warn",

		// Sometimes useful for debugging
		// Allow while(true) loops
		'no-constant-condition': "warn",

		// Seems like a good idea to error about this
		'no-control-regex': "error",

		// Warn but don't error about console statements
		'no-debugger': "warn",

		// Don't allow duplicate arguments in a function, they can cause errors
		'no-dupe-args': "error",

		// Disallow duplicate keys in an object, they can cause errors
		'no-dupe-keys': "error",

		// Disallow duplicate case statements in a switch
		'no-duplicate-case': "error",

		// Allow empty block statements, they are useful for clarity
		'no-empty': "off",

		// Disallow empty [] in regular expressions as they cause unexpected behaviour
		'no-empty-character-class': "error",

		// Overwriting the exception argument in a catch statement can cause memory leaks in some browsers
		'no-ex-assign': "error",

		// Disallow superflous boolean casts, they offer no value
		'no-extra-boolean-cast': "error",

		// Allow superflous parenthesis as they offer clarity in some cases
		'no-extra-parens': "off",

		// Disallow superflous semicolons, they offer no value
		'no-extra-semi': "error",

		// Seems like a good idea to error about this
		'no-func-assign': "error",

		// Seems like a good idea to error about this
		'no-inner-declarations': "error",

		// Seems like a good idea to error about this
		'no-invalid-regexp': "error",

		// Seems like a good idea to error about this
		'no-irregular-whitespace': "error",

		// Seems like a good idea to error about this
		'no-obj-calls': "error",

		// Not enough justification to change our existing use
		'no-prototype-builtins': "off",

		// Seems like a good idea to error about this
		// Instead of /  /  used / {"error"}/ instead
		'no-regex-spaces': "error",

		// Seems like a good idea to error about this
		'no-sparse-arrays': "error",

		// Probably an error on our part, so warn
		'no-template-curly-in-string': "warn",

		// Seems like a good idea to error about this
		'no-unexpected-multiline': "error",

		// Seems like a good idea to error about this
		'no-unreachable': "error",

		// Seems like a good idea to error about this
		'no-unsafe-finally': "error",

		// Seems like a good idea to error about this
		'no-unsafe-negation': "error",

		// Seems like a good idea to error about this
		'use-isnan': "error",

		// We use JSDoc again
		'valid-jsdoc': ["error", {
			requireParamDescription: false,
			requireReturnDescription: false
		}],

		// Seems like a good idea to error about this
		'valid-typeof': "error",


		// --------------------------------------
		// Best Practices
		// These are rules designed to prevent you from making mistakes. They either prescribe a better way of doing something or help you avoid footguns.

		// Often we only need one, setting both doesn't make sense
		// Enforces getter/setter pairs in objects
		'accessor-pairs': "off",

		// Seems sensible
		// Enforces return statements in callbacks of array's methods
		'array-callback-return': "error",

		// This rule seems buggy
		'block-scoped-var': "off",

		// Seems interesting, lets give it a go
		'class-methods-use-this': "warn",

		// Disable complexity checks, they are annoying and not that useful in detecting actual complexity
		'complexity': "off",

		// We use blank returns for break statements and for returning void
		'consistent-return': "off",

		// Always require curly braces unless the statement is all on a single line
		'curly': ["error", 'multi-line'],

		// If we don't have a default cause, it probably means we should throw an error
		'default-case': "error",

		// Dots should be on the newlines
		// chainableThingy
		//   .doSomething()
		//   .doSomethingElse()
		'dot-location': ["error", 'property'],

		// Use dot notation where possible
		'dot-notation': "error",

		// Unless you are doing == null, then force === to avoid truthy/falsey mistakes
		'eqeqeq': ["error", 'allow-null'],

		// Always use hasOwnProperty when doing for in
		'guard-for-in': "error",

		// Warn about alert statements in our code
		// Use one of the suggested alternatives instead
		// Reasoning is they could be mistaken for left over debugging statements
		'no-alert': "warn",

		// They are very slow
		'no-caller': "error",

		// Wow...
		'no-case-declarations': "error",

		// Seems like a good idea to error about this
		'no-div-regex': "error",

		// Returns in else statements offer code clarity, so disable this rule
		'no-else-return': "off",

		// Up to developer sensibility
		// disallow use of empty functions
		'no-empty-function': "off",

		// Seems sensible
		'no-empty-pattern': "error",

		// We know that == null is a null and undefined check
		'no-eq-null': "off",

		// Eval is slow and unsafe, use vm's instead
		'no-eval': "error",

		// There is never a good reason for this
		'no-extend-native': "error",

		// Don't allow useless binds
		'no-extra-bind': "error",

		// Seems sensible
		'no-extra-label': "error",

		// Don't allow switch case statements to follow through, use continue keyword instead
		'no-fallthrough': "error",

		// Use zero when doing decimals, otherwise it is confusing
		'no-floating-decimal': "error",

		// Seems sensible
		'no-global-assign': "error",

		// Cleverness is unclear
		'no-implicit-coercion': "error",

		// Seems sensible providing detection works correctly
		'no-implicit-globals': "error",

		// A sneaky way to do evals
		'no-implied-eval': "error",

		// This throws for a lot of senseless things, like chainy functions
		'no-invalid-this': "off",

		// Use proper iterators instead
		'no-iterator': "error",

		// We never use this, it seems silly to allow this
		'no-labels': "error",

		// We never use this, it seems silly to allow this
		'no-lone-blocks': "error",

		// Loop functions always cause problems, as the scope isn't clear through iterations
		'no-loop-func': "error",

		// Far too annoying
		'no-magic-numbers': "off",

		// We like multi spaces for clarity
		// E.g. We like
		// if ( blah )  return foo
		// Instead of:
		// if ( blah ) return foo
		// @TODO would be great to enforce the above
		'no-multi-spaces': "off",

		// Use ES6 template strings instead
		'no-multi-str': "error",

		// We never use this, it seems silly to allow this
		'no-new-func': "error",

		// We never use this, it seems silly to allow this
		'no-new-wrappers': "error",

		// We never use this, it seems silly to allow this
		'no-new': "error",

		// We never use this, it seems silly to allow this
		'no-octal-escape': "error",

		// We never use this, it seems silly to allow this
		'no-octal': "error",

		// We got to be pretty silly if we don't realise we are doing this
		// As such, take any usage as intentional and aware
		'no-param-reassign': "off",

		// We never use this, it seems silly to allow this
		'no-proto': "error",

		// We never use this, it seems silly to allow this
		'no-redeclare': "error",

		// No defaults for this that are useful
		'no-restricted-properties': "off",

		// We never use this, it seems silly to allow this
		'no-return-assign': "error",

		// We never use this, it seems silly to allow this
		'no-script-url': "error",

		// Seems sensible
		'no-self-assign': "error",

		// We never use this, it seems silly to allow this
		'no-self-compare': "error",

		// We never use this, it seems silly to allow this
		'no-sequences': "error",

		// We always want proper error objects as they have stack traces and respond to instanceof Error checks
		'no-throw-literal': "error",

		// Could be a getter, so warn
		'no-unmodified-loop-condition': "warn",

		// We never use this, it seems silly to allow this
		'no-unused-expressions': "error",

		// Seems sensible
		'no-unused-labels': "error",

		// Seems sensible
		'no-useless-call': "error",

		// Seems sensible
		'no-useless-concat': "error",

		// Seems sensible
		'no-useless-escape': "error",

		// We never use this, it seems silly to allow this
		'no-void': "error",

		// Warn about todos
		'no-warning-comments': ["warn", { terms: ['todo', 'fixme'], location: 'anywhere' }],

		// We never use this, it seems silly to allow this
		'no-with': "error",

		// Always specify a radix to avoid errors
		'radix': "error",

		// We appreciate the clarity late defines offer
		'vars-on-top': "off",

		// Wrap instant called functions in parenthesis for clearer intent
		'wrap-iife': "error",

		// Because we force === and never allow assignments in conditions
		// we have no need for yoda statements, so disable them
		'yoda': ["error", 'never'],


		// --------------------------------------
		// Strict Mode
		// These rules relate to using strict mode.

		// Ensure that use strict is specified to prevent the runtime erorr:
		// SyntaxError: Block-scoped declarations (let, const, function, class) not yet supported outside strict mode
		'strict': ["error", 'global'],


		// --------------------------------------
		// Variables
		// These rules have to do with variable declarations.

		// We don't care
		'init-declarations': "off",

		// Don't allow the catch method to shadow objects as browsers handle this differently
		// Update: We don't care for IE8
		'no-catch-shadow': "off",

		// Don't use delete, it disables optimisations
		'no-delete-var': "error",

		// We never use this, it seems silly to allow this
		'no-label-var': "error",

		// No useful defaults
		'no-restricted-globals': "off",

		// We never use this, it seems silly to allow this
		'no-shadow-restricted-names': "error",

		// We use shadowing
		'no-shadow': "off",

		// Makes sense
		'no-undef-init': "error",

		// Error when an undefined variable is used
		'no-undef': "error",

		// typeof blah === 'undefined' should always be used
		'no-undefined': "error",

		// Warn us when we don't use something
		'no-unused-vars': "warn",

		// Error when we try and use something before it is defined
		'no-use-before-define': "error",


		// --------------------------------------
		// Node.js and CommonJS
		// These rules are specific to JavaScript running on Node.js or using CommonJS in the browser.

		// Seems to difficult to enforce
		'callback-return': "off",

		// We use require where it is appropriate to use it
		'global-require': "off",

		// Force handling of callback errors
		'handle-callback-err': "error",

		// @TODO decide if this is good or not
		'no-mixed-requires': "error",

		// Disallow error prone syntax
		'no-new-require': "error",

		// Always use path.join for windows support
		'no-path-concat': "error",

		// We use process.env wisely
		'no-process-env': "off",

		// We know what we are doing
		'no-process-exit': "off",

		// No need to disallow any modules
		'no-restricted-modules': "off",

		// Sometimes sync methods are useful, so warn but don't error
		'no-sync': "warn",


		// --------------------------------------
		// Stylistic
		// These rules are purely matters of style and are quite subjective.

		// We don't use spaces with brackets
		'array-bracket-spacing': ["error", 'never'],

		// Disallow or enforce spaces inside of single line blocks
		'block-spacing': ["error", 'always'],

		// Opening brace on same line, closing brace on its own line, except when statement is a single line
		'brace-style': ["error", 'stroustrup', { allowSingleLine: true }],

		// Use camel case
		'camelcase': "error",

		// ES6 supports dangling commas
		'comma-dangle': ["error", 'never'],

		// Require a comma after always
		'comma-spacing': ["error", { before: false, after: true }],

		// Commas go last, we have tooling to detect if we forget a comma
		'comma-style': ["error", 'last'],

		// Require or disallow padding inside computed properties
		'computed-property-spacing': ["error", 'never'],

		// Enabling this was incredibly annoying when doing layers of nesting
		'consistent-this': "off",

		// Enable to make UNIX people's lives easier
		'eol-last': "error",

		// We never use this, it seems silly to allow this
		'func-call-spacing': ["error", 'never'],

		// This rule is not currently useful
		'func-name-matching': "off",

		// We like anonymous functions
		'func-names': "off",

		// Prefer to define functions via variables
		'func-style': ["warn", 'declaration'],

		// Nothing we want to blacklist
		// blacklist certain identifiers to prevent them being used
		'id-blacklist': "off",

		// Sometimes short names are appropriate
		'id-length': "off",

		// Camel case handles this for us
		'id-match': "off",

		// Use tabs and indent case blocks
		'indent': ["error", 'tab', {
			SwitchCase: 1,
			VariableDeclarator: 0,
			outerIIFEBody: 1,
			MemberExpression: 1,
			FunctionDeclaration: {
				body: 1,
				parameters: 0
			},
			FunctionExpression: {
				body: 1,
				parameters: 0
			}
		}],
		// ^ broken before, let us try again

		// Prefer double qoutes for JSX properties: <a b="c" />, <a b='"' />
		'jsx-quotes': ["error", 'prefer-double'],

		// Space after the colon
		'key-spacing': ["error", {
			beforeColon: false,
			afterColon: true
		}],

		// Always force a space before and after a keyword
		'keyword-spacing': ["error"],

		// we use both
		'line-comment-position': "off",

		// Enforce unix line breaks
		'linebreak-style': ["error", 'unix'],

		// Enforce new lines before block comments
		'lines-around-comment': ["error", {
			beforeBlockComment: true,
			allowBlockStart: true
		}],

		// Enforce directives with no line above but a line below
		'lines-around-directive': ["error", {
			before: 'never',
			after: 'always'
		}],

		// Disabled to ensure consistency with complexity option
		'max-depth': "off",

		// We use soft wrap
		'max-len': "off",

		// Perhaps in the future we can set this to 300 or so
		// but for now it is not useful for the things we write and maintain
		'max-lines': "off",

		// We are smart enough to know if this is bad or not
		'max-nested-callbacks': "off",

		// Sometimes we have no control over this for compat reasons, so just warn
		'max-params': ["warn", 4],

		// Let's give this a go and see what is appropriate for our usage
		'max-statements-per-line': ["warn", { max: 1 }],

		// We should be able to use whatever feels right
		'max-statements': "off",

		// Current options are not useful
		'multiline-ternary': "off",

		// Constructors should be CamelCase
		'new-cap': "error",

		// Always use parens when instantiating a class
		'new-parens': "error",

		// Too difficult to enforce correctly as too many edge-cases
		// require or disallow an empty newline after variable declarations
		'newline-after-var': "off",

		// Let the author decide
		// enforce newline after each call when chaining the calls
		'newline-per-chained-call': "off",

		// Don't use the array constructor when it is not needed
		'no-array-constructor': "error",

		// We never use bitwise, they are too clever
		'no-bitwise': "error",

		// We use continue
		'no-continue': "off",

		// We like inline comments
		'no-inline-comments': "off",

		// The code could be optimised if this error occurs
		'no-lonely-if': "error",

		// Seems sensible, let's see how we go with this
		'no-mixed-operators': "error",

		// Don't mix spaces and tabs
		// Maybe ["error", 'smart-tabs'] will be better, we will see
		'no-mixed-spaces-and-tabs': "error",

		// We use multiple empty lines for styling
		'no-multiple-empty-lines': "off",

		// Sometimes it is more understandable with a negated condition
		'no-negated-condition': "off",

		// Sometimes these are useful
		'no-nested-ternary': "off",

		// Use {} instead of new Object()
		'no-new-object': "error",

		// We use plus plus
		'no-plusplus': "off",

		// Handled by other rules
		'no-restricted-syntax': "off",

		// We use tabs
		'no-tabs': "off",

		// Sometimes ternaries are useful
		'no-ternary': "off",

		// Disallow trailing spaces
		'no-trailing-spaces': "error",

		// Sometimes this is useful when avoiding shadowing
		'no-underscore-dangle': "off",

		// Sensible
		'no-unneeded-ternary': "error",

		// Seems sensible
		'no-whitespace-before-property': "error",

		// Object indentation should be consistent within the object
		// Ignore until https://github.com/eslint/eslint/issues/7434 is done
		'object-curly-newline': ["off", { multiline: true }],

		// Desirable, but too many edge cases it turns out where it is actually preferred
		'object-curly-spacing': "off",

		// We like multiple var statements
		'one-var': "off",
		'one-var-declaration-per-line': "off",

		// Force use of shorthands when available
		'operator-assignment': ["error", 'always'],

		// Should be before, but not with =, *=, /=, += lines
		// @TODO figure out how to enforce
		'operator-linebreak': "off",

		// This rule doesn't appear to work correclty
		'padded-blocks': "off",

		// Seems like a good idea to error about this
		// was broken before, but lets give a go again
		'quote-props': ["error", 'consistent-as-needed'],

		// Use single quotes where escaping isn't needed
		'quotes': ["error", 'single', 'avoid-escape'],

		// We use YUIdoc
		'require-jsdoc': "off",

		// If semi's are used, then add spacing after
		'semi-spacing': ["error", { before: false, after: true }],

		// Never use semicolons
		'semi': ["error", 'never'],

		// Importance makes more sense than alphabetical
		'sort-keys': "off",

		// Importance makes more sense than alphabetical
		'sort-vars': "off",

		// Always force a space before a {
		'space-before-blocks': ["error", 'always'],

		// function () {, get blah () {
		'space-before-function-paren': ["error", 'always'],

		// This is for spacing between (), so doSomething( "warn", "error", 3 ) or if ( "warn" === 3 )
		// which we want for ifs, but don't want for calls
		'space-in-parens': "off",

		// We use this
		'space-infix-ops': "error",

		// We use this
		'space-unary-ops': "error",

		// We use this
		// 'spaced-line-comment': "error",
		'spaced-comment': "error",

		// When would we ever do this? Makes no sense
		'unicode-bom': ["error", 'never'],

		// We do this, seems to work well
		'wrap-regex': "error",


		// --------------------------------------
		// ECMAScript 6 / ES6

		// Sensible to create more informed and clear code
		'arrow-body-style': ["error", 'as-needed'],

		// We do this, no reason why, just what we do
		'arrow-parens': ["error", 'always'],

		// Require consistent spacing for arrow functions
		'arrow-spacing': "error",

		// Makes sense as otherwise runtime error will occur
		'constructor-super': "error",

		// Seems the most consistent location for it
		'generator-star-spacing': ["error", 'before'],

		// Makes sense
		'no-class-assign': "error",

		// Makes sense
		'no-confusing-arrow': "error",

		// Of course
		'no-const-assign': "error",

		// Of course
		'no-dupe-class-members': "error",

		// Seems sensible, may be times when we want this
		'no-duplicate-imports': "warn",

		// Seems sensible
		'no-new-symbol': "error",

		// No need to disallow any imports
		'no-restricted-imports': "off",

		// Makes sense as otherwise runtime error will occur
		'no-this-before-super': "error",

		// Seems sensible
		'no-useless-computed-key': "error",

		// Seems sensible
		'no-useless-constructor': "error",

		// Seems sensible
		'no-useless-rename': "error",

		// Of course
		// However, would be good to have this adjusted per environment
		'no-var': "warn",

		// Enforce ES6 object shorthand
		'object-shorthand': ["error", "always"],

		// Better performance when running native
		// but horrible performance if not running native as could fallback to bind
		// https://travis-ci.org/bevry/es6-benchmarks
		'prefer-arrow-callback': "off",

		// Of course
		'prefer-const': "error",

		// Makes sense
		'prefer-numeric-literals': "error",

		// Controversial change, but makes sense to move towards to reduce the risk of bad people overwriting apply and call
		// https://github.com/eslint/eslint/issues/"error"939
		// Ignoring because node does not yet support it, so we don't want to get the performance hit of using the compiled ES5 version
		'prefer-reflect': "off",

		// Makes sense to enforce, exceptions should be opted out of on case by case
		'prefer-rest-params': "error",

		// Sure, why not
		'prefer-spread': "error",

		// Too annoying to enforce
		'prefer-template': "off",

		// Makes sense
		'require-yield': "error",

		// Makes sense
		'rest-spread-spacing': ["error", 'never'],

		// Importance makes more sense than alphabetical
		'sort-imports': "off",

		// Makes sense
		'symbol-description': "error",

		// Makes sense
		'template-curly-spacing': ["error", 'never'],

		// Our preference
		'yield-star-spacing': ["error", 'both'],


		// --------------------------------------
		// Plugins

		// Not sure why, but okay
		'flow-vars/define-flow-type': "warn",
		'flow-vars/use-flow-type': "warn"
	}
}

// ------------------------------------
// Enhancements

// Load data.json file if it exists
const rules = Object.keys(config.rules)
let data = {}, devDeps = []
try {
	data = JSON.parse(require('fs').readFileSync('./package.json', 'utf8')) || {}
	devDeps = Object.keys(data.devDependencies || {})
}
catch (err) { }

// Set the parser options depending on our editions
if (data.editions) {
	const sourceEdition = data.editions[0]
	for (let syntaxIndex = 0; syntaxIndex < sourceEdition.syntaxes.length; ++syntaxIndex) {
		const syntax = sourceEdition.syntaxes[syntaxIndex]
		if (syntax === 'esnext') {
			config.parserOptions.ecmaVersion = 8
			break
		}
		else if (syntax.indexOf('es') === 0) {
			config.parserOptions.ecmaVersion = Number(syntax.substr(2))
			break
		}
	}
	config.parserOptions.sourceType = sourceEdition.syntaxes.indexOf('import') !== -1 ? 'module' : 'script'
	config.parserOptions.ecmaFeatures.jsx = sourceEdition.syntaxes.indexOf('jsx') !== -1
}
else {
	// node version
	const node = data.engines && data.engines.node && data.engines.node.replace('>=', '').replace(/ /g, '').replace(/\..+$/, '')
	config.parserOptions.ecmaVersion = node >= 6 ? 6 : 5
}

// Set the environments depending on whether we need them or not
config.env.es6 = Boolean(config.parserOptions.ecmaVersion && config.parserOptions.ecmaVersion >= 6)
config.env.node = Boolean(data.engines && data.engines.node)
config.env.browser = Boolean(data.browser)
if (config.env.browser) {
	config.env.commonjs = true
	if (config.env.node) {
		config.env['shared-node-browser'] = true
	}
}

// If not on legacy javascript, disable esnext rules
if (config.parserOptions.ecmaVersion && config.parserOptions.ecmaVersion <= 5) {
	config.rules['no-var'] = "off"
	config.rules['object-shorthand'] = ["error", 'never']
}

// Add babel parsing if installed
if (devDeps.indexOf('babel-eslint') !== -1) {
	config.parser = 'babel-eslint'
}

// Add react linting if installed
if (devDeps.indexOf('eslint-plugin-react') !== -1) {
	config.extends.push('plugin:react/recommended')
	config.plugins.push('react')
}

if (devDeps.indexOf('eslint-plugin-babel') !== -1) {
	// Remove rules that babel rules replace
	config.plugins.push('babel')
	const replacements = [
		'new-cap',
		'object-curly-spacing'
	]
	replacements.forEach(function (key) {
		if (rules.indexOf(key) !== -1) {
			config.rules['babel/' + key] = config.rules[key]
			config.rules[key] = "off"
		}
	})
}
else {
	// Remove babel rules if not using babel
	rules.forEach(function (key) {
		if (key.indexOf('babel/') === 0) {
			delete config.rules[key]
		}
	})
}

if (devDeps.indexOf('eslint-plugin-flow-vars') !== -1) {
	// Add flow plugin if installed
	config.plugins.push('flow-vars')
}
else {
	// Remove flow rules if plugin not installed
	rules.forEach(function (key) {
		if (key.indexOf('flow-vars/') === 0) {
			delete config.rules[key]
		}
	})
}


// ------------------------------------
// Export

module.exports = config
