# mocha test

{test} = require '../common-wd/per-method-test-base'

describe "wd-zombie", ->
  describe "unit", ->

    describe "per method test", ->
      
      describe "using zombie", ->
        test {}, {browserName:'zombie'}
