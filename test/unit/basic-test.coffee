# mocha test

{test} = require '../common-wd/basic-test-base'

describe "wd-zombie", ->
  describe "unit", ->

    describe "basic test", ->
      
      describe "using chrome", ->
        test {}, {browserName:'zombie'}
