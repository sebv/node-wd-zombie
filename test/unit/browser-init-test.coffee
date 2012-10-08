# mocha test

should = require 'should'

wd = require '../common-wd/wd-with-cov'

describe "wd", ->
  describe "local", ->
    describe "browser init tests", ->
      describe "default init", ->      
        it "should open zombie browser", (done) ->
          @timeout 15000
          browser = wd.remote()
          browser.defaultCapabilities.should.eql { 
            browserName: 'zombie',
            version: '',
            javascriptEnabled: true,
            platform: 'ANY' }
          browser.init (err) ->
            should.not.exist err
            browser.sessionCapabilities (err, capabilities) ->
              should.not.exist err
              capabilities.browserName.should.equal 'zombie'
              browser.quit (err) ->
                should.not.exist err
                done null
      
      describe "browser.defaultCapabilities", ->      
        it "should open zombie browser", (done) ->
          @timeout 15000
          browser = wd.remote()
          browser.defaultCapabilities.browserName = 'zombie'
          browser.defaultCapabilities.javascriptEnabled = false
          browser.defaultCapabilities.should.eql { 
            browserName: 'zombie',
            version: '',
            javascriptEnabled: false,
            platform: 'ANY',
          }
          browser.init (err) ->
            should.not.exist err
            browser.sessionCapabilities (err, capabilities) ->
              should.not.exist err
              capabilities.browserName.should.equal 'zombie'
              browser.quit (err) ->
                should.not.exist err
                done null
      
      describe "desired only", ->      
        it "should open zombie browser", (done) ->
          @timeout 15000
          browser = wd.remote()
          browser.defaultCapabilities.should.eql { 
            browserName: 'zombie',
            version: '',
            javascriptEnabled: true,
            platform: 'ANY' }
          browser.init {browserName: 'chrome'}, (err) ->
            should.not.exist err
            browser.sessionCapabilities (err, capabilities) ->
              should.not.exist err
              capabilities.browserName.should.equal 'zombie'
              browser.quit (err) ->
                should.not.exist err
                done null

      describe "desired overiding defaultCapabilities", ->      
        it "should open zombie browser", (done) ->
          @timeout 15000
          browser = wd.remote()
          browser.defaultCapabilities.browserName = 'zombie'
          browser.defaultCapabilities.should.eql { 
            browserName: 'zombie',
            version: '',
            javascriptEnabled: true,
            platform: 'ANY' }
          browser.init {browserName: 'zombie'}, (err) ->
            should.not.exist err
            browser.sessionCapabilities (err, capabilities) ->
              should.not.exist err
              capabilities.browserName.should.equal 'zombie'
              browser.quit (err) ->
                should.not.exist err
                done null
    
            