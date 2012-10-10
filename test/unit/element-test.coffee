# mocha test

{test} = require '../common-wd/element-test-base'

describe "wd-zombie", ->
  describe "unit", ->

    describe "element test", ->
      
      describe "using zombie", ->
        test {}, {browserName:'zombie'}
