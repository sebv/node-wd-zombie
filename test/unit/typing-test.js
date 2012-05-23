// Generated by CoffeeScript 1.3.3
(function() {
  var CoffeeScript, altKey, altKeyTracking, app, async, clearAndCheck, enterKey, executeCoffee, express, inputAndCheck, keysAndCheck, leakDetector, nullKey, preventDefault, returnKey, runTestWith, should, typeAndCheck, unbind, valueShouldEqual, wd;

  should = require('should');

  express = require('express');

  CoffeeScript = require('coffee-script');

  async = require('async');

  leakDetector = (require('../common/leak-detector'))();

  wd = require('../../lib/wd-zombie');

  altKey = wd.SPECIAL_KEYS['Alt'];

  nullKey = wd.SPECIAL_KEYS['NULL'];

  returnKey = wd.SPECIAL_KEYS['Return'];

  enterKey = wd.SPECIAL_KEYS['Enter'];

  executeCoffee = function(browser, script, done) {
    var scriptAsJs;
    scriptAsJs = CoffeeScript.compile(script, {
      bare: 'on'
    });
    return browser.execute(scriptAsJs, function(err) {
      should.not.exist(err);
      return done(null);
    });
  };

  valueShouldEqual = function(browser, element, expected, done) {
    return browser.getValue(element, function(err, res) {
      should.not.exist(err);
      res.should.equal(expected);
      return done(null);
    });
  };

  typeAndCheck = function(browser, _sel, chars, expected, done) {
    return browser.elementByCss(_sel, function(err, inputField) {
      should.not.exist(err);
      should.exist(inputField);
      return async.series([
        function(done) {
          return browser.type(inputField, chars, function(err) {
            should.not.exist(err);
            return done(null);
          });
        }, function(done) {
          return valueShouldEqual(browser, inputField, expected, done);
        }
      ], function(err) {
        should.not.exist(err);
        return done(null);
      });
    });
  };

  keysAndCheck = function(browser, _sel, chars, expected, done) {
    return browser.elementByCss(_sel, function(err, inputField) {
      should.not.exist(err);
      should.exist(inputField);
      return async.series([
        function(done) {
          return browser.moveTo(inputField, function(err) {
            should.not.exist(err);
            return done(null);
          });
        }, function(done) {
          return browser.keys(chars, function(err) {
            should.not.exist(err);
            return done(null);
          });
        }, function(done) {
          return valueShouldEqual(browser, inputField, expected, done);
        }
      ], function(err) {
        should.not.exist(err);
        return done(null);
      });
    });
  };

  inputAndCheck = function(browser, method, _sel, chars, expected, done) {
    switch (method) {
      case 'type':
        return typeAndCheck(browser, _sel, chars, expected, done);
      case 'keys':
        return keysAndCheck(browser, _sel, chars, expected, done);
    }
  };

  clearAndCheck = function(browser, _sel, done) {
    return browser.elementByCss(_sel, function(err, inputField) {
      should.not.exist(err);
      should.exist(inputField);
      return async.series([
        function(done) {
          return browser.clear(inputField, function(err) {
            should.not.exist(err);
            return done(null);
          });
        }, function(done) {
          return valueShouldEqual(browser, inputField, "", done);
        }
      ], function(err) {
        should.not.exist(err);
        return done(null);
      });
    });
  };

  preventDefault = function(browser, _sel, eventType, done) {
    var script;
    script = "$('" + _sel + "')." + eventType + " (e) ->\n  e.preventDefault()";
    return executeCoffee(browser, script, done);
  };

  unbind = function(browser, _sel, eventType, done) {
    var script;
    script = "$('" + _sel + "').unbind '" + eventType + "' ";
    return executeCoffee(browser, script, done);
  };

  altKeyTracking = function(browser, _sel, done) {
    var script;
    script = "f = $('" + _sel + "')\nf.keydown (e) ->\n  if e.altKey\n    f.val 'altKey on'\n  else\n    f.val 'altKey off'\n  e.preventDefault()";
    return executeCoffee(browser, script, done);
  };

  runTestWith = function(remoteWdConfig, desired) {
    var browser, testMethod;
    browser = null;
    testMethod = function(method, sel) {
      return {
        "1/ typing nothing": function(test) {
          return inputAndCheck(browser, method, sel, "", "", (function(err) {
            return test.done(err);
          }));
        },
        "2/ typing []": function(test) {
          return inputAndCheck(browser, method, sel, [], "", (function(err) {
            return test.done(err);
          }));
        },
        "3/ typing 'Hello'": function(test) {
          return inputAndCheck(browser, method, sel, 'Hello', 'Hello', (function(err) {
            return test.done(err);
          }));
        },
        "4/ clear": function(test) {
          return clearAndCheck(browser, sel, (function(err) {
            return test.done(err);
          }));
        },
        "5/ typing ['Hello']": function(test) {
          return inputAndCheck(browser, method, sel, ['Hello'], 'Hello', (function(err) {
            return test.done(err);
          }));
        },
        "6/ clear": function(test) {
          return clearAndCheck(browser, sel, (function(err) {
            return test.done(err);
          }));
        },
        "7/ typing ['Hello',' ','World','!']": function(test) {
          return inputAndCheck(browser, method, sel, ['Hello', ' ', 'World', '!'], 'Hello World!', (function(err) {
            return test.done(err);
          }));
        },
        "8/ clear": function(test) {
          return clearAndCheck(browser, sel, (function(err) {
            return test.done(err);
          }));
        },
        "9/ typing 'Hello\\n'": function(test) {
          var expected;
          expected = (sel.match(/input/) ? 'Hello' : 'Hello\n');
          return inputAndCheck(browser, method, sel, 'Hello\n', expected, (function(err) {
            return test.done(err);
          }));
        },
        "10/ typing '\\r'": function(test) {
          var expected;
          expected = (sel.match(/input/) ? 'Hello' : 'Hello\n\r');
          return inputAndCheck(browser, method, sel, '\r', expected, (function(err) {
            return test.done(err);
          }));
        },
        "11/ typing [returnKey]": function(test) {
          var expected;
          expected = (sel.match(/input/) ? 'Hello' : 'Hello\n\r\r');
          return inputAndCheck(browser, method, sel, [returnKey], expected, (function(err) {
            return test.done(err);
          }));
        },
        "12/ typing [enterKey]": function(test) {
          var expected;
          expected = (sel.match(/input/) ? 'Hello' : 'Hello\n\r\r\r');
          return inputAndCheck(browser, method, sel, [enterKey], expected, (function(err) {
            return test.done(err);
          }));
        },
        "13/ typing ' World!'": function(test) {
          var expected;
          expected = (sel.match(/input/) ? 'Hello World!' : 'Hello\n\r\r\r World!');
          return inputAndCheck(browser, method, sel, ' World!', expected, (function(err) {
            return test.done(err);
          }));
        },
        "14/ clear": function(test) {
          return clearAndCheck(browser, sel, (function(err) {
            return test.done(err);
          }));
        },
        "15/ preventing default on keydown": function(test) {
          return preventDefault(browser, sel, 'keydown', (function(err) {
            return test.done(err);
          }));
        },
        "16/ typing 'Hello'": function(test) {
          return inputAndCheck(browser, method, sel, 'Hello', '', (function(err) {
            return test.done(err);
          }));
        },
        "17/ unbinding keydown": function(test) {
          return unbind(browser, sel, 'keydown', (function(err) {
            return test.done(err);
          }));
        },
        "18/ typing 'Hello'": function(test) {
          return inputAndCheck(browser, method, sel, 'Hello', 'Hello', (function(err) {
            return test.done(err);
          }));
        },
        "19/ clear": function(test) {
          return clearAndCheck(browser, sel, (function(err) {
            return test.done(err);
          }));
        },
        "20/ preventing default on keypress": function(test) {
          return preventDefault(browser, sel, 'keypress', (function(err) {
            return test.done(err);
          }));
        },
        "21/ typing 'Hello'": function(test) {
          return inputAndCheck(browser, method, sel, 'Hello', '', (function(err) {
            return test.done(err);
          }));
        },
        "22/ unbinding keypress": function(test) {
          return unbind(browser, sel, 'keypress', (function(err) {
            return test.done(err);
          }));
        },
        "23/ typing 'Hello'": function(test) {
          return inputAndCheck(browser, method, sel, 'Hello', 'Hello', (function(err) {
            return test.done(err);
          }));
        },
        "24/ clear": function(test) {
          return clearAndCheck(browser, sel, (function(err) {
            return test.done(err);
          }));
        },
        "25/ preventing default on keyup": function(test) {
          return preventDefault(browser, sel, 'keyup', (function(err) {
            return test.done(err);
          }));
        },
        "26/ typing 'Hello'": function(test) {
          return inputAndCheck(browser, method, sel, 'Hello', 'Hello', (function(err) {
            return test.done(err);
          }));
        },
        "27/ unbinding keypress": function(test) {
          return unbind(browser, sel, 'keyup', (function(err) {
            return test.done(err);
          }));
        },
        "28/ clear": function(test) {
          return clearAndCheck(browser, sel, (function(err) {
            return test.done(err);
          }));
        },
        "29/ adding alt key tracking": function(test) {
          return altKeyTracking(browser, sel, (function(err) {
            return test.done(err);
          }));
        },
        "30/ typing ['a']": function(test) {
          return inputAndCheck(browser, method, sel, ['a'], 'altKey off', (function(err) {
            return test.done(err);
          }));
        },
        "31/ typing [altKey,nullKey,'a']": function(test) {
          return inputAndCheck(browser, method, sel, [altKey, nullKey, 'a'], 'altKey off', (function(err) {
            return test.done(err);
          }));
        },
        "32/ typing [altKey,'a']": function(test) {
          return inputAndCheck(browser, method, sel, [altKey, 'a'], 'altKey on', (function(err) {
            return test.done(err);
          }));
        },
        "33/ typing ['a']": function(test) {
          var expected;
          expected = (method === 'type' ? 'altKey off' : 'altKey on');
          return inputAndCheck(browser, method, sel, ['a'], expected, (function(err) {
            return test.done(err);
          }));
        },
        "34/ clear": function(test) {
          return clearAndCheck(browser, sel, (function(err) {
            return test.done(err);
          }));
        },
        "35/ typing [nullKey]": function(test) {
          return inputAndCheck(browser, method, sel, [nullKey], '', (function(err) {
            return test.done(err);
          }));
        },
        "36/ typing ['a']": function(test) {
          return inputAndCheck(browser, method, sel, ['a'], 'altKey off', (function(err) {
            return test.done(err);
          }));
        },
        "37/ clear": function(test) {
          return clearAndCheck(browser, sel, (function(err) {
            return test.done(err);
          }));
        },
        "38/ unbinding keydown": function(test) {
          return unbind(browser, sel, 'keydown', (function(err) {
            return test.done(err);
          }));
        }
      };
    };
    return {
      setUp: function(done) {
        return done(null);
      },
      "wd.remote": function(test) {
        browser = wd.remote(remoteWdConfig);
        browser.on("status", function(info) {
          return console.log("\u001b[36m%s\u001b[0m", info);
        });
        browser.on("command", function(meth, path) {
          return console.log(" > \u001b[33m%s\u001b[0m: %s", meth, path);
        });
        return test.done();
      },
      "init": function(test) {
        return browser.init(desired, function(err) {
          should.not.exist(err);
          return test.done();
        });
      },
      "get": function(test) {
        return browser.get("http://127.0.0.1:8181/type-test-page.html", function(err) {
          should.not.exist(err);
          return test.done();
        });
      },
      "input": {
        "type": testMethod("type", "#type input"),
        "keys": testMethod("keys", "#type input")
      },
      "textarea": {
        "type": testMethod("type", "#type textarea"),
        "keys": testMethod("keys", "#type textarea")
      },
      "quit": function(test) {
        return browser.quit(function(err) {
          should.not.exist(err);
          return test.done();
        });
      }
    };
  };

  app = null;

  exports.wd = {
    "per method test": {
      'starting express': function(test) {
        app = express.createServer();
        app.use(express["static"](__dirname + '/assets'));
        app.listen(8181);
        return test.done();
      },
      zombie: runTestWith({}, {
        browserName: 'zombie'
      }),
      'stopping express': function(test) {
        app.close();
        return test.done();
      },
      'checking leaks': leakDetector.lookForLeaks
    }
  };

}).call(this);
