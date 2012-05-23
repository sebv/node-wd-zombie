# nodeunit test

should = require 'should'
express = require 'express'
CoffeeScript = require 'coffee-script'      
async = require 'async'      

leakDetector = (require '../common/leak-detector')()

wd = require '../../lib/wd-zombie'

altKey = wd.SPECIAL_KEYS['Alt']
nullKey = wd.SPECIAL_KEYS['NULL']
returnKey = wd.SPECIAL_KEYS['Return']
enterKey = wd.SPECIAL_KEYS['Enter']

executeCoffee = (browser, script , done ) ->  
  scriptAsJs = CoffeeScript.compile script, bare:'on'      
  browser.execute scriptAsJs, (err) ->
    should.not.exist err
    done(null)      

valueShouldEqual = (browser,element,expected, done) ->  
  browser.getValue element, (err,res) ->
    should.not.exist err
    res.should.equal expected
    done null      

click = (browser, _sel, done) ->
  browser.elementByCss _sel, (err,inputField) ->
    should.not.exist err
    should.exist inputField
    browser.clickElement inputField , (err) ->
      should.not.exist err
      done null

typeAndCheck = (browser, _sel, chars, expected, done) ->
  browser.elementByCss _sel, (err,inputField) ->
    should.not.exist err
    should.exist inputField
    async.series [
      (done) ->
        browser.type inputField, chars , (err) ->
          should.not.exist err
          done null
      (done) -> valueShouldEqual browser, inputField, expected, done    
    ], (err) ->
      should.not.exist err
      done null

keysAndCheck = (browser, _sel, chars, expected, done) ->
  browser.elementByCss _sel, (err,inputField) ->
    should.not.exist err
    should.exist inputField
    async.series [
      (done) ->
        browser.moveTo inputField , (err) ->
          should.not.exist err
          done null
      (done) ->
        browser.keys chars , (err) ->
          should.not.exist err
          done null
      (done) -> valueShouldEqual browser, inputField, expected, done    
    ], (err) ->
      should.not.exist err
      done null

inputAndCheck = (browser, method, _sel, chars, expected, done) ->
  switch method
    when 'type'
      typeAndCheck browser, _sel, chars, expected, done
    when 'keys'
      keysAndCheck browser, _sel, chars, expected, done

clearAndCheck = (browser, _sel, done) ->
  browser.elementByCss _sel, (err,inputField) ->
    should.not.exist err
    should.exist inputField
    async.series [
      (done) ->
        browser.clear inputField, (err) ->
          should.not.exist err
          done null
      (done) -> valueShouldEqual browser, inputField, "", done    
    ], (err) ->
      should.not.exist err
      done null

preventDefault = (browser, _sel, eventType, done) ->
  script =
    """
      $('#{_sel}').#{eventType} (e) ->
        e.preventDefault()
    """
  executeCoffee browser, script , done

unbind = (browser, _sel, eventType, done) ->
  script =
    """
      $('#{_sel}').unbind '#{eventType}' 
    """
  executeCoffee browser, script , done

altKeyTracking = (browser, _sel, done) ->
  script =
    """
      f = $('#{_sel}')
      f.keydown (e) ->
        if e.altKey
          f.val 'altKey on'
        else
          f.val 'altKey off'
        e.preventDefault()
    """    
  executeCoffee browser, script , done

         
runTestWith = (remoteWdConfig, desired) -> 
  browser = null;  
  testMethod = (method, sel) ->
    {
      
      "1/ click": (test) ->
        click browser, sel, ( (err) -> test.done(err) )         
      "1/ typing nothing": (test) -> 
        inputAndCheck browser, method, sel, "", "", ( (err) -> test.done(err) )
      "2/ typing []": (test) -> 
        inputAndCheck browser, method, sel, [], "", ( (err) -> test.done(err) )
      "3/ typing 'Hello'": (test) -> 
        inputAndCheck browser, method, sel, 'Hello', 'Hello', ( (err) -> test.done(err) )
      "4/ clear": (test) -> 
        clearAndCheck browser, sel, ( (err) -> test.done(err) )
      "5/ typing ['Hello']": (test) -> 
        inputAndCheck browser, method, sel, ['Hello'], 'Hello', ( (err) -> test.done(err) )
      "6/ clear": (test) -> 
        clearAndCheck browser, sel, ( (err) -> test.done(err) )
      "7/ typing ['Hello',' ','World','!']": (test) -> 
        inputAndCheck browser, method, sel, ['Hello',' ','World','!'], 'Hello World!', ( (err) -> test.done(err) )
      "8/ clear": (test) -> 
        clearAndCheck browser, sel, ( (err) -> test.done(err) )
      "9/ typing 'Hello\\n'": (test) ->
        expected = (if sel.match /input/ then 'Hello' else 'Hello\n') 
        inputAndCheck browser, method, sel, 'Hello\n', expected, ( (err) -> test.done(err) )
      "10/ typing '\\r'": (test) -> 
        expected = (if sel.match /input/ then 'Hello' else 'Hello\n\n') 
        inputAndCheck browser, method, sel, '\r', expected, ( (err) -> test.done(err) )
      "11/ typing [returnKey]": (test) -> 
        expected = (if sel.match /input/ then 'Hello' else 'Hello\n\n\n') 
        inputAndCheck browser, method, sel, [returnKey], expected, ( (err) -> test.done(err) )
      "12/ typing [enterKey]": (test) -> 
        expected = (if sel.match /input/ then 'Hello' else 'Hello\n\n\n\n') 
        inputAndCheck browser, method, sel, [enterKey], expected, ( (err) -> test.done(err) )
      "13/ typing ' World!'": (test) -> 
        expected = (if sel.match /input/ then 'Hello World!' else 'Hello\n\n\n\n World!') 
        inputAndCheck browser, method, sel, ' World!', expected, ( (err) -> test.done(err) )
      "14/ clear": (test) -> 
        clearAndCheck browser, sel, ( (err) -> test.done(err) )
      "15/ preventing default on keydown": (test) -> 
        preventDefault browser, sel, 'keydown', ( (err) -> test.done(err) )      
      "16/ typing 'Hello'": (test) -> 
        inputAndCheck browser, method, sel, 'Hello', '', ( (err) -> test.done(err) )
      "17/ unbinding keydown": (test) ->
        unbind browser, sel, 'keydown', ( (err) -> test.done(err) )      
      "18/ typing 'Hello'": (test) -> 
        inputAndCheck browser, method, sel, 'Hello', 'Hello', ( (err) -> test.done(err) )
      "19/ clear": (test) -> 
        clearAndCheck browser, sel, ( (err) -> test.done(err) )      
      "20/ preventing default on keypress": (test) -> 
        preventDefault browser, sel, 'keypress', ( (err) -> test.done(err) )      
      "21/ typing 'Hello'": (test) -> 
        inputAndCheck browser, method, sel, 'Hello', '', ( (err) -> test.done(err) )
      "22/ unbinding keypress": (test) ->
        unbind browser, sel, 'keypress', ( (err) -> test.done(err) )      
      "23/ typing 'Hello'": (test) -> 
        inputAndCheck browser, method, sel, 'Hello', 'Hello', ( (err) -> test.done(err) )
      "24/ clear": (test) -> 
        clearAndCheck browser, sel, ( (err) -> test.done(err) )      
      "25/ preventing default on keyup": (test) -> 
        preventDefault browser, sel, 'keyup', ( (err) -> test.done(err) )      
      "26/ typing 'Hello'": (test) -> 
        inputAndCheck browser, method, sel, 'Hello', 'Hello', ( (err) -> test.done(err) )
      "27/ unbinding keypress": (test) ->
        unbind browser, sel, 'keyup', ( (err) -> test.done(err) )      
      "28/ clear": (test) -> 
        clearAndCheck browser, sel, ( (err) -> test.done(err) )   
      "29/ adding alt key tracking": (test) ->         
        altKeyTracking browser, sel, ( (err) -> test.done(err) )   
      "30/ typing ['a']": (test) -> 
        inputAndCheck browser, method, sel, ['a'], 'altKey off', ( (err) -> test.done(err) )
      "31/ typing [altKey,nullKey,'a']": (test) -> 
        inputAndCheck browser, method, sel, [altKey,nullKey,'a'], 'altKey off', ( (err) -> test.done(err) )
      "32/ typing [altKey,'a']": (test) -> 
        inputAndCheck browser, method, sel, [altKey,'a'], 'altKey on', ( (err) -> test.done(err) )
      "33/ typing ['a']": (test) -> 
        expected = (if method is 'type' then 'altKey off' else 'altKey on') 
        inputAndCheck browser, method, sel, ['a'], expected, ( (err) -> test.done(err) )
      "34/ clear": (test) -> 
        clearAndCheck browser, sel, ( (err) -> test.done(err) )   
      "35/ typing [nullKey]": (test) -> 
        inputAndCheck browser, method, sel, [nullKey], '', ( (err) -> test.done(err) )
      "36/ typing ['a']": (test) -> 
        inputAndCheck browser, method, sel, ['a'], 'altKey off', ( (err) -> test.done(err) )        
      "37/ clear": (test) -> 
        clearAndCheck browser, sel, ( (err) -> test.done(err) )   
      "38/ unbinding keydown": (test) ->
        unbind browser, sel, 'keydown', ( (err) -> test.done(err) )     
    }
  {
    setUp: (done) ->
      done null
    "wd.remote": (test) ->
      browser = wd.remote remoteWdConfig    
      browser.on "status", (info) ->
        console.log "\u001b[36m%s\u001b[0m", info
      browser.on "command", (meth, path) ->
        console.log " > \u001b[33m%s\u001b[0m: %s", meth, path
      test.done()
        
    "init": (test) ->
      browser.init desired, (err) ->
        should.not.exist err
        test.done()
        
    "get": (test) ->
      browser.get "http://127.0.0.1:8181/type-test-page.html", (err) ->
        should.not.exist err
        test.done()
    
    

    "input":      
      "type": testMethod "type", "#type input"
      "keys": testMethod "keys", "#type input"
    "textarea":
      "type": testMethod "type", "#type textarea"      
      "keys": testMethod "keys", "#type textarea"
          
    "quit": (test) ->        
      browser.quit (err) ->
        should.not.exist err
        test.done()    
    
  }

app = null      

exports.wd =
  "per method test":    
    
    'starting express': (test) ->
      app = express.createServer()
      app.use(express.static(__dirname + '/assets'));
      app.listen 8181
      test.done()
    
    zombie: (runTestWith {}, {browserName: 'zombie'})

    'stopping express': (test) ->
      app.close()
      test.done()

    'checking leaks': leakDetector.lookForLeaks
