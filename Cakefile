DEV_DIRS = ['lib','test']
COFFEE_PATHS = DEV_DIRS.concat ['index.coffee']
JS_PATHS = DEV_DIRS.concat ['index.js']
TEST_ENV = ['test/sync-test.coffee']

u = require 'sv-cake-utils'

task 'compile', 'Compile All coffee files', ->
  u.coffee.compile COFFEE_PATHS

task 'compile:watch', 'Compile All coffee files and watch for changes', ->
  u.coffee.compile COFFEE_PATHS, watch:true

task 'clean', 'Remove all js files', ->  
  u.js.clean JS_PATHS, undefined, /browser\-scripts/

task 'test', 'Run All tests', ->
  u.nodeunit.test 'test/unit'

  #./node_modules/.bin/nodeunit 'test/unit/*.coffee'

task 'grep:dirty', 'Lookup for debugger and console.log in code', ->
  u.grep.debug()
  u.grep.log()
    