(function() {
  var Event, EventEmitter, EventSystem, Group, child_process, fs, path, request, type, util,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; },
    __slice = Array.prototype.slice;

  fs = require('fs');

  path = require('path');

  EventEmitter = require('events').EventEmitter;

  request = null;

  child_process = null;

  type = {
    get: function(value) {
      var result, type, _i, _len, _ref;
      result = 'object';
      _ref = ['array', 'regex', 'function', 'boolean', 'number', 'string', 'null', 'undefined'];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        type = _ref[_i];
        if (this[type](value)) {
          result = type;
          break;
        }
      }
      return result;
    },
    object: function(value) {
      return this.get(value) === 'object';
    },
    "function": function(value) {
      return value instanceof Function;
    },
    regex: function(value) {
      return value instanceof RegExp;
    },
    array: function(value) {
      return value instanceof Array;
    },
    boolean: function(value) {
      return typeof value === 'boolean';
    },
    number: function(value) {
      return (value != null) && typeof value.toPrecision !== 'undefined';
    },
    string: function(value) {
      return (value != null) && typeof value.charAt !== 'undefined';
    },
    'null': function(value) {
      return value === null;
    },
    'undefined': function(value) {
      return typeof value === 'undefined';
    },
    empty: function(value) {
      return value != null;
    }
  };

  Event = (function() {

    Event.prototype.name = null;

    Event.prototype.locked = false;

    Event.prototype.finished = false;

    function Event(_arg) {
      this.name = _arg.name;
    }

    return Event;

  })();

  EventSystem = (function(_super) {

    __extends(EventSystem, _super);

    function EventSystem() {
      EventSystem.__super__.constructor.apply(this, arguments);
    }

    EventSystem.prototype._eventSystemEvents = null;

    EventSystem.prototype.event = function(eventName) {
      var _base;
      this._eventSystemEvents || (this._eventSystemEvents = {});
      return (_base = this._eventSystemEvents)[eventName] || (_base[eventName] = new Event(eventName));
    };

    EventSystem.prototype.lock = function(eventName, next) {
      var event,
        _this = this;
      event = this.event(eventName);
      if (event.locked === false) {
        event.locked = true;
        try {
          this.emit(eventName + ':locked');
        } catch (err) {
          if (typeof next === "function") next(err);
          return this;
        } finally {
          if (typeof next === "function") next();
        }
      } else {
        this.onceUnlocked(eventName, function(err) {
          if (err) return typeof next === "function" ? next(err) : void 0;
          return _this.lock(eventName, next);
        });
      }
      return this;
    };

    EventSystem.prototype.unlock = function(eventName, next) {
      var event;
      event = this.event(eventName);
      event.locked = false;
      try {
        this.emit(eventName + ':unlocked');
      } catch (err) {
        if (typeof next === "function") next(err);
        return this;
      } finally {
        if (typeof next === "function") next();
      }
      return this;
    };

    EventSystem.prototype.start = function(eventName, next) {
      var _this = this;
      this.lock(eventName, function(err) {
        var event;
        if (err) return typeof next === "function" ? next(err) : void 0;
        event = _this.event(eventName);
        event.finished = false;
        try {
          return _this.emit(eventName + ':started');
        } catch (err) {
          if (typeof next === "function") next(err);
          return _this;
        } finally {
          if (typeof next === "function") next();
        }
      });
      return this;
    };

    EventSystem.prototype.finish = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this.finished.apply(this, args);
    };

    EventSystem.prototype.finished = function(eventName, next) {
      var event,
        _this = this;
      event = this.event(eventName);
      event.finished = true;
      this.unlock(eventName, function(err) {
        if (err) return typeof next === "function" ? next(err) : void 0;
        try {
          return _this.emit(eventName + ':finished');
        } catch (err) {
          if (typeof next === "function") next(err);
          return _this;
        } finally {
          if (typeof next === "function") next();
        }
      });
      return this;
    };

    EventSystem.prototype.onceUnlocked = function(eventName, next) {
      var event;
      event = this.event(eventName);
      if (event.locked) {
        this.once(eventName + ':unlocked', next);
      } else {
        if (typeof next === "function") next();
      }
      return this;
    };

    EventSystem.prototype.onceFinished = function(eventName, next) {
      var event;
      event = this.event(eventName);
      if (event.finished) {
        if (typeof next === "function") next();
      } else {
        this.once(eventName + ':finished', next);
      }
      return this;
    };

    EventSystem.prototype.whenFinished = function(eventName, next) {
      var event;
      event = this.event(eventName);
      if (event.finished) if (typeof next === "function") next();
      this.on(eventName + ':finished', next);
      return this;
    };

    EventSystem.prototype.when = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this.on.apply(this, args);
    };

    EventSystem.prototype.block = function(eventNames, next) {
      var done, eventName, total, _i, _len;
      if ((eventNames instanceof Array) === false) {
        if (typeof eventNames === 'string') {
          eventNames = eventNames.split(/[,\s]+/g);
        } else {
          return typeof next === "function" ? next(new Error('Unknown eventNames type')) : void 0;
        }
      }
      total = eventNames.length;
      done = 0;
      for (_i = 0, _len = eventNames.length; _i < _len; _i++) {
        eventName = eventNames[_i];
        this.lock(eventName, function(err) {
          if (err) {
            done = total;
            return typeof next === "function" ? next(err) : void 0;
          }
          done++;
          if (done === total) return typeof next === "function" ? next() : void 0;
        });
      }
      return this;
    };

    EventSystem.prototype.unblock = function(eventNames, next) {
      var done, eventName, total, _i, _len;
      if ((eventNames instanceof Array) === false) {
        if (typeof eventNames === 'string') {
          eventNames = eventNames.split(/[,\s]+/g);
        } else {
          return typeof next === "function" ? next(new Error('Unknown eventNames type')) : void 0;
        }
      }
      total = eventNames.length;
      done = 0;
      for (_i = 0, _len = eventNames.length; _i < _len; _i++) {
        eventName = eventNames[_i];
        this.unlock(eventName, function(err) {
          if (err) {
            done = total;
            return typeof next === "function" ? next(err) : void 0;
          }
          done++;
          if (done === total) return typeof next === "function" ? next() : void 0;
        });
      }
      return this;
    };

    EventSystem.prototype.cycle = function(eventName, data, next) {
      var listener, listeners, tasks, _i, _len;
      listeners = this.listeners(eventName);
      tasks = new util.Group(function(err) {
        return typeof next === "function" ? next(err) : void 0;
      });
      tasks.total = listeners.length;
      for (_i = 0, _len = listeners.length; _i < _len; _i++) {
        listener = listeners[_i];
        listener(data, tasks.completer());
      }
      return this;
    };

    return EventSystem;

  })(EventEmitter);

  Group = (function() {

    Group.prototype.total = 0;

    Group.prototype.completed = 0;

    Group.prototype.exited = false;

    Group.prototype.queue = [];

    Group.prototype.queueIndex = 0;

    Group.prototype.mode = 'async';

    Group.prototype.next = function() {
      throw new Error('Groups require a completion callback');
    };

    function Group(next, mode) {
      this.next = next;
      this.queue = [];
      if (mode) this.mode = mode;
    }

    Group.prototype.nextTask = function() {
      var task;
      ++this.queueIndex;
      if (this.queue[this.queueIndex] != null) {
        task = this.queue[this.queueIndex];
        return task();
      }
    };

    Group.prototype.complete = function(err) {
      if (this.exited === false) {
        if (err) {
          return this.exit(err);
        } else {
          ++this.completed;
          if (this.completed === this.total) {
            return this.exit();
          } else if (this.mode === 'sync') {
            return this.nextTask();
          }
        }
      }
    };

    Group.prototype.completer = function() {
      var _this = this;
      return function(err) {
        return _this.complete(err);
      };
    };

    Group.prototype.exit = function(err) {
      if (err == null) err = false;
      if (this.exited === false) {
        this.exited = true;
        return typeof this.next === "function" ? this.next(err) : void 0;
      } else {
        return typeof this.next === "function" ? this.next(new Error('Group has already exited')) : void 0;
      }
    };

    Group.prototype.push = function(task) {
      ++this.total;
      return this.queue.push(task);
    };

    Group.prototype.run = function() {
      var task, _i, _len, _ref, _results;
      if (this.mode === 'sync') {
        this.queueIndex = 0;
        if (this.queue[this.queueIndex] != null) {
          task = this.queue[this.queueIndex];
          return task();
        }
      } else {
        _ref = this.queue;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          task = _ref[_i];
          _results.push(task());
        }
        return _results;
      }
    };

    Group.prototype.async = function() {
      this.mode = 'async';
      return this.run();
    };

    Group.prototype.sync = function() {
      this.mode = 'sync';
      return this.run();
    };

    return Group;

  })();

  util = {
    Event: Event,
    EventSystem: EventSystem,
    Group: Group,
    parallel: function(tasks, next) {
      var group, task, _i, _len, _results;
      group = new this.Group(function(err) {
        return typeof next === "function" ? next(err) : void 0;
      });
      group.total = tasks.length;
      _results = [];
      for (_i = 0, _len = tasks.length; _i < _len; _i++) {
        task = tasks[_i];
        _results.push(task(group.completer()));
      }
      return _results;
    },
    type: type,
    exec: function(commands, options, callback) {
      var command, createHandler, mode, results, tasks, _i, _len;
      if (!child_process) child_process = require('child_process');
      mode = options.mode || null;
      results = [];
      tasks = new util.Group(function() {
        if (mode === 'single') {
          return callback.apply(callback, results[0]);
        } else {
          return callback.apply(callback, [results]);
        }
      });
      createHandler = function(command) {
        return function() {
          return child_process.exec(command, options, function() {
            var args, err;
            args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
            err = args[0] || null;
            results.push(args);
            return tasks.complete(err);
          });
        };
      };
      if (commands instanceof Array) {
        mode || (mode = 'multiple');
      } else {
        mode || (mode = 'single');
        commands = [commands];
      }
      for (_i = 0, _len = commands.length; _i < _len; _i++) {
        command = commands[_i];
        tasks.push(createHandler(command));
      }
      return tasks.sync();
    },
    cp: function(src, dst, next) {
      return fs.readFile(src, 'binary', function(err, data) {
        if (err) {
          console.log('bal-util.cp: cp failed on:', src);
          return typeof next === "function" ? next(err) : void 0;
        }
        return fs.writeFile(dst, data, 'binary', function(err) {
          if (err) console.log('bal-util.cp: writeFile failed on:', dst);
          return typeof next === "function" ? next(err) : void 0;
        });
      });
    },
    getParentPathSync: function(p) {
      var parentPath;
      parentPath = p.replace(/[\/\\][^\/\\]+$/, '');
      return parentPath;
    },
    ensurePath: function(p, next) {
      p = p.replace(/[\/\\]$/, '');
      return path.exists(p, function(exists) {
        var parentPath;
        if (exists) return typeof next === "function" ? next() : void 0;
        parentPath = util.getParentPathSync(p);
        return util.ensurePath(parentPath, function(err) {
          if (err) {
            console.log('bal-util.ensurePath: failed to ensure the path:', parentPath);
            return typeof next === "function" ? next(err) : void 0;
          }
          return fs.mkdir(p, 0700, function(err) {
            return path.exists(p, function(exists) {
              if (!exists) {
                console.log('bal-util.ensurePath: failed to create the directory:', p);
                return typeof next === "function" ? next(new Error('Failed to create the directory ' + p)) : void 0;
              }
              return typeof next === "function" ? next() : void 0;
            });
          });
        });
      });
    },
    prefixPathSync: function(path, parentPath) {
      path = path.replace(/[\/\\]$/, '');
      if (/^([a-zA-Z]\:|\/)/.test(path) === false) path = parentPath + '/' + path;
      return path;
    },
    isDirectory: function(fileFullPath, next) {
      return fs.stat(fileFullPath, function(err, fileStat) {
        if (err) {
          console.log('bal-util.isDirectory: stat failed on:', fileFullPath);
          return typeof next === "function" ? next(err) : void 0;
        }
        return typeof next === "function" ? next(null, fileStat.isDirectory()) : void 0;
      });
    },
    resolvePath: function(srcPath, parentPath, next) {
      return fs.realpath(srcPath, function(err, fileFullPath) {
        var fileRelativePath;
        if (err) {
          console.log('bal-util.resolvePath: realpath failed on:', srcPath);
          return typeof next === "function" ? next(err, srcPath) : void 0;
        } else if (fileFullPath.substring(0, parentPath.length) !== parentPath) {
          err = new Error('Hacker! Tried to create a file outside our working directory: ' + fileFullPath);
          return typeof next === "function" ? next(err, fileFullPath, false) : void 0;
        } else {
          fileRelativePath = fileFullPath.substring(parentPath.length);
          return typeof next === "function" ? next(null, fileFullPath, fileRelativePath) : void 0;
        }
      });
    },
    generateSlugSync: function(fileFullPath) {
      var result;
      result = fileFullPath.replace(/[^a-zA-Z0-9]/g, '-').replace(/^-/, '').replace(/-+/, '-');
      return result;
    },
    scan: function(files, fileAction, dirAction, next) {
      var actions,
        _this = this;
      actions = {
        directory: function() {
          return _this.scandir(files, fileAction, dirAction, next);
        },
        files: function() {
          var file, tasks, _i, _len;
          tasks = new util.Group(next);
          tasks.total += files.length;
          for (_i = 0, _len = files.length; _i < _len; _i++) {
            file = files[_i];
            _this.scan(fileFullPath, fileAction, dirAction, tasks.completer());
          }
          return true;
        }
      };
      if (typeof files.charAt !== 'undefined') {
        return util.isDirectory(function(err, isDirectory) {
          if (err) {
            return typeof next === "function" ? next(err) : void 0;
          } else if (isDirectory) {
            return actions.directory();
          } else {
            files = [file];
            return actions.files();
          }
        });
      } else if (files instanceof Array) {
        return actions.files();
      } else {
        return typeof next === "function" ? next(new Error('bal-util.scandir: unsupported files type:', typeof files, files)) : void 0;
      }
    },
    scandir: function(parentPath, fileAction, dirAction, next, relativePath) {
      var list, tasks, tree;
      list = {};
      tree = {};
      tasks = new this.Group(function(err) {
        return typeof next === "function" ? next(err, list, tree) : void 0;
      });
      return fs.readdir(parentPath, function(err, files) {
        if (tasks.exited) {} else if (err) {
          console.log('bal-util.scandir: readdir has failed on:', parentPath);
          return tasks.exit(err);
        } else if (!files.length) {
          return tasks.exit();
        } else {
          return files.forEach(function(file) {
            var fileFullPath, fileRelativePath;
            ++tasks.total;
            fileFullPath = parentPath + '/' + file;
            fileRelativePath = (relativePath ? relativePath + '/' : '') + file;
            return util.isDirectory(fileFullPath, function(err, isDirectory) {
              var complete;
              if (tasks.exited) {} else if (err) {
                console.log('bal-util.scandir: isDirectory has failed on:', fileFullPath);
                return tasks.exit(err);
              } else if (isDirectory) {
                complete = function(err, skip, subtreeCallback) {
                  if (err) return tasks.exit(err);
                  if (tasks.exited) return tasks.exit();
                  if (skip !== true) {
                    list[fileRelativePath] = 'dir';
                    tree[file] = {};
                    return util.scandir(fileFullPath, fileAction, dirAction, function(err, _list, _tree) {
                      var filePath, fileType;
                      tree[file] = _tree;
                      for (filePath in _list) {
                        if (!__hasProp.call(_list, filePath)) continue;
                        fileType = _list[filePath];
                        list[filePath] = fileType;
                      }
                      if (tasks.exited) {
                        return tasks.exit();
                      } else if (err) {
                        console.log('bal-util.scandir: has failed on:', fileFullPath);
                        return tasks.exit(err);
                      } else if (subtreeCallback) {
                        return subtreeCallback(tasks.completer());
                      } else {
                        return tasks.complete();
                      }
                    }, fileRelativePath);
                  } else {
                    return tasks.complete();
                  }
                };
                if (dirAction) {
                  return dirAction(fileFullPath, fileRelativePath, complete);
                } else if (dirAction === false) {
                  return complete(err, true);
                } else {
                  return complete(err, false);
                }
              } else {
                complete = function(err, skip) {
                  if (err) return tasks.exit(err);
                  if (tasks.exited) return tasks.exit();
                  if (!skip) {
                    list[fileRelativePath] = 'file';
                    tree[file] = true;
                  }
                  return tasks.complete();
                };
                if (fileAction) {
                  return fileAction(fileFullPath, fileRelativePath, complete);
                } else if (fileAction === false) {
                  return complete(err, true);
                } else {
                  return complete(err, false);
                }
              }
            });
          });
        }
      });
    },
    cpdir: function(srcPath, outPath, next) {
      return util.scandir(srcPath, function(fileSrcPath, fileRelativePath, next) {
        var fileOutPath;
        fileOutPath = outPath + '/' + fileRelativePath;
        return util.ensurePath(path.dirname(fileOutPath), function(err) {
          if (err) {
            console.log('bal-util.cpdir: failed to create the path for the file:', fileSrcPath);
            return typeof next === "function" ? next(err) : void 0;
          }
          return util.cp(fileSrcPath, fileOutPath, function(err) {
            if (err) {
              console.log('bal-util.cpdir: failed to copy the child file:', fileSrcPath);
            }
            return typeof next === "function" ? next(err) : void 0;
          });
        });
      }, null, next);
    },
    rmdir: function(parentPath, next) {
      return path.exists(parentPath, function(exists) {
        if (!exists) return typeof next === "function" ? next() : void 0;
        return util.scandir(parentPath, function(fileFullPath, fileRelativePath, next) {
          return fs.unlink(fileFullPath, function(err) {
            if (err) {
              console.log('bal-util.rmdir: failed to remove the child file:', fileFullPath);
            }
            return typeof next === "function" ? next(err) : void 0;
          });
        }, function(fileFullPath, fileRelativePath, next) {
          return typeof next === "function" ? next(null, false, function(next) {
            return fs.rmdir(fileFullPath, function(err) {
              if (err) {
                console.log('bal-util.rmdir: failed to remove the child directory:', fileFullPath);
              }
              return typeof next === "function" ? next(err) : void 0;
            });
          }) : void 0;
        }, function(err, list, tree) {
          if (err) {
            return typeof next === "function" ? next(err, list, tree) : void 0;
          }
          return fs.rmdir(parentPath, function(err) {
            if (err) {
              console.log('bal-util.rmdir: failed to remove the parent directory:', parentPath);
            }
            return typeof next === "function" ? next(err, list, tree) : void 0;
          });
        });
      });
    },
    writetree: function(dstPath, tree, next) {
      var tasks;
      tasks = new this.Group(function(err) {
        return typeof next === "function" ? next(err) : void 0;
      });
      util.ensurePath(dstPath, function(err) {
        var fileFullPath, fileRelativePath, value;
        if (err) return tasks.exit(err);
        for (fileRelativePath in tree) {
          if (!__hasProp.call(tree, fileRelativePath)) continue;
          value = tree[fileRelativePath];
          ++tasks.total;
          fileFullPath = dstPath + '/' + fileRelativePath.replace(/^\/+/, '');
          if (typeof value === 'object') {
            util.writetree(fileFullPath, value, tasks.completer());
          } else {
            fs.writeFile(fileFullPath, value, function(err) {
              if (err) {
                console.log('bal-util.writetree: writeFile failed on:', fileFullPath);
              }
              return tasks.complete(err);
            });
          }
        }
        if (tasks.total === 0) tasks.exit();
      });
    },
    expandPath: function(path, dir, _arg, next) {
      var cwd, cwdPath, expandedPath, realpath;
      cwd = _arg.cwd, realpath = _arg.realpath;
      if (cwd == null) cwd = false;
      if (realpath == null) realpath = false;
      expandedPath = null;
      cwdPath = false;
      if (cwd) {
        if (type.string(cwd)) {
          cwdPath = cwd;
        } else {
          cwdPath = process.cwd();
        }
      }
      if (!type.string(path)) {
        return typeof next === "function" ? next(new Error('bal-util.expandPath: path needs to be a string')) : void 0;
      }
      if (!type.string(dir)) {
        return typeof next === "function" ? next(new Error('bal-util.expandPath: dir needs to be a string')) : void 0;
      }
      if (/^\/|\:/.test(path)) {
        expandedPath = path;
      } else {
        if (cwd && /^\./.test(path)) {
          expandedPath = cwdPath + '/' + path;
        } else {
          expandedPath = dir + '/' + path;
        }
      }
      if (realpath) {
        fs.realpath(expandedPath, function(err, fileFullPath) {
          if (err) {
            console.log('bal-util.expandPath: realpath failed on:', expandedPath);
            return typeof next === "function" ? next(err, expandedPath) : void 0;
          }
          return typeof next === "function" ? next(null, fileFullPath) : void 0;
        });
      } else {
        return typeof next === "function" ? next(null, expandedPath) : void 0;
      }
    },
    expandPaths: function(paths, dir, options, next) {
      var expandedPaths, path, tasks, _i, _len;
      options || (options = {});
      expandedPaths = [];
      tasks = new this.Group(function(err) {
        return typeof next === "function" ? next(err, expandedPaths) : void 0;
      });
      tasks.total += paths.length;
      for (_i = 0, _len = paths.length; _i < _len; _i++) {
        path = paths[_i];
        this.expandPath(path, dir, options, function(err, expandedPath) {
          if (err) return tasks.exit(err);
          expandedPaths.push(expandedPath);
          return tasks.complete(err);
        });
      }
      if (!paths.length) tasks.exit();
    },
    versionCompare: function(v1, operator, v2) {
      var compare, i, numVersion, prepVersion, vm, x;
      i = x = compare = 0;
      vm = {
        'dev': -6,
        'alpha': -5,
        'a': -5,
        'beta': -4,
        'b': -4,
        'RC': -3,
        'rc': -3,
        '#': -2,
        'p': -1,
        'pl': -1
      };
      prepVersion = function(v) {
        v = ('' + v).replace(/[_\-+]/g, '.');
        v = v.replace(/([^.\d]+)/g, '.$1.').replace(/\.{2,}/g, '.');
        if (!v.length) {
          return [-8];
        } else {
          return v.split('.');
        }
      };
      numVersion = function(v) {
        if (!v) {
          return 0;
        } else {
          if (isNaN(v)) {
            return vm[v] || -7;
          } else {
            return parseInt(v, 10);
          }
        }
      };
      v1 = prepVersion(v1);
      v2 = prepVersion(v2);
      x = Math.max(v1.length, v2.length);
      for (i = 0; 0 <= x ? i <= x : i >= x; 0 <= x ? i++ : i--) {
        if (v1[i] === v2[i]) continue;
        v1[i] = numVersion(v1[i]);
        v2[i] = numVersion(v2[i]);
        if (v1[i] < v2[i]) {
          compare = -1;
          break;
        } else if (v1[i] > v2[i]) {
          compare = 1;
          break;
        }
      }
      if (!operator) return compare;
      switch (operator) {
        case '>':
        case 'gt':
          return compare > 0;
        case '>=':
        case 'ge':
          return compare >= 0;
        case '<=':
        case 'le':
          return compare <= 0;
        case '==':
        case '=':
        case 'eq':
        case 'is':
          return compare === 0;
        case '<>':
        case '!=':
        case 'ne':
        case 'isnt':
          return compare !== 0;
        case '':
        case '<':
        case 'lt':
          return compare < 0;
        default:
          return null;
      }
    },
    packageCompare: function(_arg) {
      var details, errorCallback, local, newVersionCallback, oldVersionCallback, remote,
        _this = this;
      local = _arg.local, remote = _arg.remote, newVersionCallback = _arg.newVersionCallback, oldVersionCallback = _arg.oldVersionCallback, errorCallback = _arg.errorCallback;
      details = {};
      try {
        details.local = JSON.parse(fs.readFileSync(local).toString());
        if (!request) request = require('request');
        return request(remote, function(err, response, body) {
          if (!err && response.statusCode === 200) {
            details.remote = JSON.parse(body);
            if (!_this.versionCompare(details.local.version, '>=', details.remote.version)) {
              if (newVersionCallback) return newVersionCallback(details);
            } else {
              if (oldVersionCallback) return oldVersionCallback(details);
            }
          }
        });
      } catch (err) {
        if (errorCallback) return errorCallback(err);
      }
    }
  };

  module.exports = util;

}).call(this);
