'use strict'

class A { }
class a { }
const b = class { }
class C extends A { }

class D {
	z () {
		return this
	}
}
class E extends D { }
class F extends E {
	/* :: greeting:?string; */
	constructor () {
		super()
		this.greeting = 'hello'
	}
}

async function AsyncFunction () { }

module.exports = { A, a, b, C, D, E, F, AsyncFunction }
