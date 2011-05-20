var vows = require('vows');
var assert = require('assert');
var coffee = require('coffee-script');
var util = require(__dirname+'/../lib/util.coffee');
var path = require('path');

// Test Data
var srcPath = __dirname+'/src',
	outPath = __dirname+'/out',
	writetree = {
		'index.html': '<html>',
		'blog': {
			'post1.md': 'my post',
			'post2.md': 'my post2'
		},
		'styles': {
			'style.css': 'blah',
			'themes': {
				'balupton': {
					'style.css': 'body { display:none; }'
				},
				'style.css': 'blah'
			}
		}
	},
	scantree = {
		'index.html': true,
		'blog': {
			'post1.md': true,
			'post2.md': true
		},
		'styles': {
			'style.css': true,
			'themes': {
				'balupton': {
					'style.css': true
				},
				'style.css': true
			}
		}
	};

vows.describe('bal-util/util').addBatch({
	'writetree': {
		topic: function(){
			util.writetree(
				// Path
				srcPath,
				// Tree
				writetree,
				// Complete
				this.callback
			);
		},
		'did not error': function(err){
			assert.equal(err,false);
		},
		'scandir': {
			topic: function() {
				callback = this.callback;
				util.scandir(srcPath,false,false,function(err,list,tree){
					callback(null,err,list,tree);
				});
			},
			'did not error': function(z,err,list,tree){
				assert.equal(err,false);
			},
			'files were written': function(z,err,list,tree){
				assert.deepEqual(tree,scantree);
			},
			'cpdir': {
				topic: function(){
					callback = this.callback;
					util.cpdir(srcPath,outPath,function(err){
						callback(null,err);
					});
				},
				'did not error': function(z,err,list,tree){
					assert.equal(err,false);
				},
				'scandir': {
					topic: function() {
						callback = this.callback;
						util.scandir(srcPath,false,false,function(err,list,tree){
							callback(null,err,list,tree);
						});
					},
					'did not error': function(z,err,list,tree){
						assert.equal(err,false);
					},
					'files were copied': function(z,err,list,tree){
						assert.deepEqual(tree,scantree);
					},
					'rmdir-src': {
						topic: function(){
							callback = this.callback;
							util.rmdir(srcPath,function(err){
								console.log('Ignore the error about to happen, as seeing this proves the callback did fire');
								callback(null,err);
							});
						},
						'did not error': function(z,err){
							assert.equal(err||false,false);
						},
						'path.exists': function(){
							var exists = path.existsSync(srcPath);
							assert.equal(exists,false);
						}
					},
					'rmdir-out': {
						topic: function(){
							callback = this.callback;
							util.rmdir(outPath,function(err){
								callback(null,err);
							});
						},
						'did not error': function(z,err){
							assert.equal(err||false,false);
						},
						'path.exists': function(){
							var exists = path.existsSync(outPath);
							assert.equal(exists,false);
						}
					}
				}
			}
		}
	}
}).export(module);

function assertError(assertion, value, fail) {
	try {
		assertion(value);
		fail = true;
	} catch (e) {/* Success */}

	fail && assert.fail(value, assert.AssertionError, 
							   'expected an AssertionError for {actual}',
							   'assertError', assertError);
}
