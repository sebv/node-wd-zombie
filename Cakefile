DEV_DIRS = ['lib','test']
COFFEE_PATHS = DEV_DIRS.concat ['index.coffee']
JS_PATHS = DEV_DIRS.concat ['index.js']
TEST_ENV = ['test/sync-test.coffee']

cp = require 'child_process'
u = require 'sv-cake-utils'
async = require 'async'
fs = require 'fs'
prepareTest = require './tools/prepare-tests'

task 'compile', 'Compile All coffee files', ->
  u.coffee.compile COFFEE_PATHS

task 'compile:watch', 'Compile All coffee files and watch for changes', ->
  u.coffee.compile COFFEE_PATHS, watch:true

task 'clean', 'Remove all js files', ->  
  u.js.clean JS_PATHS, undefined, /browser\-scripts/

task 'test', 'Run All tests', ->
  u.mocha.test 'test/unit', (status) ->
    process.exit status is status isnt 0

  #./node_modules/.bin/nodeunit 'test/unit/*.coffee'

task 'grep:dirty', 'Lookup for debugger and console.log in code', ->
  u.grep.debug()
  u.grep.log()

task 'prepare:test', 'Import tests from wd and disable test for non-implemented methods', ->
  sourceDir = "#{__dirname}/node_modules/wd/test/common"
  targetDir = "test/common-wd"
  async.series [
    (done) -> u.exec "mkdir -p #{targetDir}", done
    (done) -> u.exec "rm -rf #{targetDir}/*", done
    (done) -> u.exec "cp -r #{sourceDir}/* #{targetDir}/", done
    (done) -> u.exec "rm -f #{targetDir}/*.js", done
    (done) -> u.exec "rm -f #{targetDir}/*test-base.coffee", done
    (done) -> 
      cp.execFile 'find', [ sourceDir  ] , (err, stdout, stderr) ->
        files = (stdout.split '\n').filter( (name) -> name.match /.+-test\-base\.coffee/ )
        async.forEachSeries files, (f, done) ->
          filename = f.replace "#{sourceDir}/" , '' 
          prepareTest sourceDir, targetDir, filename, done 
        , (err) ->
          done err
  ] , (err) ->
    if err?
      console.error err
      process.exit(1)
      
