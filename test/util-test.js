var assert = require('assert');
var coffee = require('coffee-script');
var util = require(__dirname+'/../lib/util.coffee');
var path = require('path');

// Test Data
var srcPath = __dirname+'/src',
	outPath = __dirname+'/out',
	nonPath = __dirname+'/asd',
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

// Tests
var tests = {
	'writetree': function(beforeExit){
		var nTests = 6, nTestsCompleted = 0;

		// writetree
		util.writetree(srcPath,writetree,function(err){
			++nTestsCompleted;

			// no error
			assert.equal(err||false,false, 'writetree: no error');

			// scandir
			util.scandir(srcPath,false,false,function(err,list,tree){
				++nTestsCompleted;
			
				// no error
				assert.equal(err||false,false, 'writetree: scandir: no error');

				// files were written
				assert.deepEqual(tree,scantree, 'writetree: scandir: files were written');

				// cpdir
				util.cpdir(srcPath,outPath,function(err){
					++nTestsCompleted;

					// no error
					assert.equal(err||false,false, 'writree: scandir: cpdir: no error');
							
					// scandir
					util.scandir(srcPath,false,false,function(err,list,tree){
						++nTestsCompleted;

						// no error
						assert.equal(err||false,false, 'writree: scandir: cpdir: scandir: no error');

						// files were copied
						assert.deepEqual(tree,scantree, 'writree: scandir: cpdir: scandir: files were copied');

						// rmdir
						util.rmdir(srcPath,function(err){
							++nTestsCompleted;

							// no error
							assert.equal(err||false,false, 'writree: scandir: cpdir: scandir: rmdir: no error');

							// dir was deleted
							var exists = path.existsSync(srcPath);
							assert.equal(exists,false, 'writree: scandir: cpdir: scandir: rmdir: delete successful');
						});

						// rmdir
						util.rmdir(outPath,function(err){
							++nTestsCompleted;

							// no error
							assert.equal(err||false,false, 'writree: scandir: cpdir: scandir: rmdir: no error');

							// dir was deleted
							var exists = path.existsSync(outPath);
							assert.equal(exists,false, 'writree: scandir: cpdir: scandir: rmdir: delete successful');
						});
					});
				});
			});
		});

		// async
		beforeExit(function(){
			assert.equal(nTests, nTestsCompleted, 'all writetree tests ran');
		});
	},
	'rmdir-non': function(beforeExit){
		var nTests = 1, nTestsCompleted = 0;

		// rmdir
		util.rmdir(nonPath,function(err){
			++nTestsCompleted;

			// no error
			assert.equal(err||false,false, 'rmdir-non: no error');
		});

		// async
		beforeExit(function(){
			assert.equal(nTests, nTestsCompleted, 'all rmdir tests ran');
		});
	}
};

// Export
module.exports = tests;