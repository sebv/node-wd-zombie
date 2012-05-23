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
  inputFieldSel = "#type input" 
  textareaFieldSel = "#type textarea" 
  {
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
      "type":
        "1/ typing nothing": (test) -> 
          typeAndCheck browser, inputFieldSel, "", "", ( (err) -> test.done(err) )
        "2/ typing []": (test) -> 
          typeAndCheck browser, inputFieldSel, [], "", ( (err) -> test.done(err) )
        "3/ typing 'Hello'": (test) -> 
          typeAndCheck browser, inputFieldSel, 'Hello', 'Hello', ( (err) -> test.done(err) )
        "4/ clear": (test) -> 
          clearAndCheck browser, inputFieldSel, ( (err) -> test.done(err) )
        "5/ typing ['Hello']": (test) -> 
          typeAndCheck browser, inputFieldSel, ['Hello'], 'Hello', ( (err) -> test.done(err) )
        "6/ clear": (test) -> 
          clearAndCheck browser, inputFieldSel, ( (err) -> test.done(err) )
        "7/ typing ['Hello',' ','World','!']": (test) -> 
          typeAndCheck browser, inputFieldSel, ['Hello',' ','World','!'], 'Hello World!', ( (err) -> test.done(err) )
        "8/ clear": (test) -> 
          clearAndCheck browser, inputFieldSel, ( (err) -> test.done(err) )
        "9/ typing 'Hello\\n'": (test) -> 
          typeAndCheck browser, inputFieldSel, 'Hello\n', 'Hello', ( (err) -> test.done(err) )
        "10/ typing '\\r'": (test) -> 
          typeAndCheck browser, inputFieldSel, '\r', 'Hello', ( (err) -> test.done(err) )
        "11/ typing [returnKey]": (test) -> 
          typeAndCheck browser, inputFieldSel, [returnKey], 'Hello', ( (err) -> test.done(err) )
        "13/ typing [enterKey]": (test) -> 
          typeAndCheck browser, inputFieldSel, [enterKey], 'Hello', ( (err) -> test.done(err) )
        "14/ typing ' World!'": (test) -> 
          typeAndCheck browser, inputFieldSel, ' World!', 'Hello World!', ( (err) -> test.done(err) )
        "15/ clear": (test) -> 
          clearAndCheck browser, inputFieldSel, ( (err) -> test.done(err) )
        "16/ preventing default on keydown": (test) -> 
          preventDefault browser, inputFieldSel, 'keydown', ( (err) -> test.done(err) )      
        "17/ typing 'Hello'": (test) -> 
          typeAndCheck browser, inputFieldSel, 'Hello', '', ( (err) -> test.done(err) )
        "18/ unbinding keydown": (test) ->
          unbind browser, inputFieldSel, 'keydown', ( (err) -> test.done(err) )      
        "19/ typing 'Hello'": (test) -> 
          typeAndCheck browser, inputFieldSel, 'Hello', 'Hello', ( (err) -> test.done(err) )
        "20/ clear": (test) -> 
          clearAndCheck browser, inputFieldSel, ( (err) -> test.done(err) )      
        "21/ preventing default on keypress": (test) -> 
          preventDefault browser, inputFieldSel, 'keypress', ( (err) -> test.done(err) )      
        "22/ typing 'Hello'": (test) -> 
          typeAndCheck browser, inputFieldSel, 'Hello', '', ( (err) -> test.done(err) )
        "23/ unbinding keypress": (test) ->
          unbind browser, inputFieldSel, 'keypress', ( (err) -> test.done(err) )      
        "24/ typing 'Hello'": (test) -> 
          typeAndCheck browser, inputFieldSel, 'Hello', 'Hello', ( (err) -> test.done(err) )
        "25/ clear": (test) -> 
          clearAndCheck browser, inputFieldSel, ( (err) -> test.done(err) )      
        "26/ preventing default on keyup": (test) -> 
          preventDefault browser, inputFieldSel, 'keyup', ( (err) -> test.done(err) )      
        "27/ typing 'Hello'": (test) -> 
          typeAndCheck browser, inputFieldSel, 'Hello', 'Hello', ( (err) -> test.done(err) )
        "28/ unbinding keypress": (test) ->
          unbind browser, inputFieldSel, 'keyup', ( (err) -> test.done(err) )      
        "30/ clear": (test) -> 
          clearAndCheck browser, inputFieldSel, ( (err) -> test.done(err) )   
        "31/ adding alt key tracking": (test) ->         
          altKeyTracking browser, inputFieldSel, ( (err) -> test.done(err) )   
        "32/ typing ['a']": (test) -> 
          typeAndCheck browser, inputFieldSel, ['a'], 'altKey off', ( (err) -> test.done(err) )
        "33/ typing [altKey,nullKey,'a']": (test) -> 
          typeAndCheck browser, inputFieldSel, [altKey,nullKey,'a'], 'altKey off', ( (err) -> test.done(err) )
        "34/ typing [altKey,'a']": (test) -> 
          typeAndCheck browser, inputFieldSel, [altKey,'a'], 'altKey on', ( (err) -> test.done(err) )
        "35/ typing ['a']": (test) -> 
          typeAndCheck browser, inputFieldSel, ['a'], 'altKey off', ( (err) -> test.done(err) )
        "36/ clear": (test) -> 
          clearAndCheck browser, inputFieldSel, ( (err) -> test.done(err) )   
        "37/ typing [nullKey]": (test) -> 
          typeAndCheck browser, inputFieldSel, [nullKey], '', ( (err) -> test.done(err) )
        "38/ typing ['a']": (test) -> 
          keysAndCheck browser, inputFieldSel, ['a'], 'altKey off', ( (err) -> test.done(err) )        
        "39/ clear": (test) -> 
          clearAndCheck browser, inputFieldSel, ( (err) -> test.done(err) )   
        "40/ unbinding keydown": (test) ->
          unbind browser, inputFieldSel, 'keydown', ( (err) -> test.done(err) )      
          
      "keys":
        "1/ typing nothing": (test) -> 
          keysAndCheck browser, inputFieldSel, "", "", ( (err) -> test.done(err) )
        "2/ typing []": (test) -> 
          keysAndCheck browser, inputFieldSel, [], "", ( (err) -> test.done(err) )
        "3/ typing 'Hello'": (test) -> 
          keysAndCheck browser, inputFieldSel, 'Hello', 'Hello', ( (err) -> test.done(err) )
        "4/ clear": (test) -> 
          clearAndCheck browser, inputFieldSel, ( (err) -> test.done(err) )
        "5/ typing ['Hello']": (test) -> 
          keysAndCheck browser, inputFieldSel, ['Hello'], 'Hello', ( (err) -> test.done(err) )
        "6/ clear": (test) -> 
          clearAndCheck browser, inputFieldSel, ( (err) -> test.done(err) )
        "7/ typing ['Hello',' ','World','!']": (test) -> 
          keysAndCheck browser, inputFieldSel, ['Hello',' ','World','!'], 'Hello World!', ( (err) -> test.done(err) )
        "8/ clear": (test) -> 
          clearAndCheck browser, inputFieldSel, ( (err) -> test.done(err) )
        "9/ typing 'Hello\\n'": (test) -> 
          keysAndCheck browser, inputFieldSel, 'Hello\n', 'Hello', ( (err) -> test.done(err) )
        "10/ typing '\\r'": (test) -> 
          keysAndCheck browser, inputFieldSel, '\r', 'Hello', ( (err) -> test.done(err) )
        "11/ typing [returnKey]": (test) -> 
          keysAndCheck browser, inputFieldSel, [returnKey], 'Hello', ( (err) -> test.done(err) )
        "13/ typing [enterKey]": (test) -> 
          keysAndCheck browser, inputFieldSel, [enterKey], 'Hello', ( (err) -> test.done(err) )
        "14/ typing ' World!'": (test) -> 
          keysAndCheck browser, inputFieldSel, ' World!', 'Hello World!', ( (err) -> test.done(err) )
        "15/ clear": (test) -> 
          clearAndCheck browser, inputFieldSel, ( (err) -> test.done(err) )
        "16/ preventing default on keydown": (test) -> 
          preventDefault browser, inputFieldSel, 'keydown', ( (err) -> test.done(err) )      
        "17/ typing 'Hello'": (test) -> 
          keysAndCheck browser, inputFieldSel, 'Hello', '', ( (err) -> test.done(err) )
        "18/ unbinding keydown": (test) ->
          unbind browser, inputFieldSel, 'keydown', ( (err) -> test.done(err) )      
        "19/ typing 'Hello'": (test) -> 
          keysAndCheck browser, inputFieldSel, 'Hello', 'Hello', ( (err) -> test.done(err) )
        "20/ clear": (test) -> 
          clearAndCheck browser, inputFieldSel, ( (err) -> test.done(err) )      
        "21/ preventing default on keypress": (test) -> 
          preventDefault browser, inputFieldSel, 'keypress', ( (err) -> test.done(err) )      
        "22/ typing 'Hello'": (test) -> 
          keysAndCheck browser, inputFieldSel, 'Hello', '', ( (err) -> test.done(err) )
        "23/ unbinding keypress": (test) ->
          unbind browser, inputFieldSel, 'keypress', ( (err) -> test.done(err) )      
        "24/ typing 'Hello'": (test) -> 
          keysAndCheck browser, inputFieldSel, 'Hello', 'Hello', ( (err) -> test.done(err) )
        "25/ clear": (test) -> 
          clearAndCheck browser, inputFieldSel, ( (err) -> test.done(err) )      
        "26/ preventing default on keyup": (test) -> 
          preventDefault browser, inputFieldSel, 'keyup', ( (err) -> test.done(err) )      
        "27/ typing 'Hello'": (test) -> 
          keysAndCheck browser, inputFieldSel, 'Hello', 'Hello', ( (err) -> test.done(err) )
        "28/ unbinding keypress": (test) ->
          unbind browser, inputFieldSel, 'keyup', ( (err) -> test.done(err) )      
        "30/ clear": (test) -> 
          clearAndCheck browser, inputFieldSel, ( (err) -> test.done(err) )           
        "31/ adding alt key tracking": (test) ->         
          altKeyTracking browser, inputFieldSel, ( (err) -> test.done(err) )   
        "32/ typing ['a']": (test) -> 
          keysAndCheck browser, inputFieldSel, ['a'], 'altKey off', ( (err) -> test.done(err) )        
        "33/ typing [altKey,nullKey,'a']": (test) -> 
          keysAndCheck browser, inputFieldSel, [altKey,nullKey,'a'], 'altKey off', ( (err) -> test.done(err) )        
        "34/ typing [altKey,'a']": (test) -> 
          keysAndCheck browser, inputFieldSel, [altKey,'a'], 'altKey on', ( (err) -> test.done(err) )        
        "35/ typing ['a']": (test) -> 
          keysAndCheck browser, inputFieldSel, ['a'], 'altKey on', ( (err) -> test.done(err) )        
        "36/ clear": (test) -> 
          clearAndCheck browser, inputFieldSel, ( (err) -> test.done(err) )   
        "37/ typing [nullKey]": (test) -> 
          keysAndCheck browser, inputFieldSel, [nullKey], '', ( (err) -> test.done(err) )
        "38/ typing ['a']": (test) -> 
          keysAndCheck browser, inputFieldSel, ['a'], 'altKey off', ( (err) -> test.done(err) )        
        "39/ clear": (test) -> 
          clearAndCheck browser, inputFieldSel, ( (err) -> test.done(err) )   
        "40/ unbinding keypress": (test) ->
          unbind browser, inputFieldSel, 'keypress', ( (err) -> test.done(err) )      
    
    "textarea":
      "type":
        "1/ typing nothing": (test) -> 
          typeAndCheck browser, textareaFieldSel, "", "", ( (err) -> test.done(err) )
        "2/ typing []": (test) -> 
          typeAndCheck browser, textareaFieldSel, [], "", ( (err) -> test.done(err) )
        "3/ typing 'Hello'": (test) -> 
          typeAndCheck browser, textareaFieldSel, 'Hello', 'Hello', ( (err) -> test.done(err) )
        "4/ clear": (test) -> 
          clearAndCheck browser, textareaFieldSel, ( (err) -> test.done(err) )
        "5/ typing ['Hello']": (test) -> 
          typeAndCheck browser, textareaFieldSel, ['Hello'], 'Hello', ( (err) -> test.done(err) )
        "6/ clear": (test) -> 
          clearAndCheck browser, textareaFieldSel, ( (err) -> test.done(err) )
        "7/ typing ['Hello',' ','World','!']": (test) -> 
          typeAndCheck browser, textareaFieldSel, ['Hello',' ','World','!'], 'Hello World!', ( (err) -> test.done(err) )
        "8/ clear": (test) -> 
          clearAndCheck browser, textareaFieldSel, ( (err) -> test.done(err) )
        "9/ typing 'Hello\\n'": (test) -> 
          typeAndCheck browser, textareaFieldSel, 'Hello\n', 'Hello\n', ( (err) -> test.done(err) )      
        "10/ typing '\\r'": (test) -> 
          typeAndCheck browser, textareaFieldSel, '\r', 'Hello\n\r', ( (err) -> test.done(err) )
        "11/ typing [returnKey]": (test) -> 
          typeAndCheck browser, textareaFieldSel, [returnKey], 'Hello\n\r\r', ( (err) -> test.done(err) )      
        "13/ typing [enterKey]": (test) -> 
          typeAndCheck browser, textareaFieldSel, [enterKey], 'Hello\n\r\r\r', ( (err) -> test.done(err) )
        "14/ typing ' World!'": (test) -> 
          typeAndCheck browser, textareaFieldSel, ' World!', 'Hello\n\r\r\r World!', ( (err) -> test.done(err) )
        "15/ clear": (test) -> 
          clearAndCheck browser, textareaFieldSel, ( (err) -> test.done(err) )      
        "16/ preventing default on keydown": (test) -> 
          preventDefault browser, textareaFieldSel, 'keydown', ( (err) -> test.done(err) )      
        "17/ typing 'Hello'": (test) -> 
          typeAndCheck browser, textareaFieldSel, 'Hello', '', ( (err) -> test.done(err) )      
        "18/ unbinding keydown": (test) ->
          unbind browser, textareaFieldSel, 'keydown', ( (err) -> test.done(err) )      
        "19/ typing 'Hello'": (test) -> 
          typeAndCheck browser, textareaFieldSel, 'Hello', 'Hello', ( (err) -> test.done(err) )
        "20/ clear": (test) -> 
          clearAndCheck browser, textareaFieldSel, ( (err) -> test.done(err) )      
        "21/ preventing default on keypress": (test) -> 
          preventDefault browser, textareaFieldSel, 'keypress', ( (err) -> test.done(err) )      
        "22/ typing 'Hello'": (test) -> 
          typeAndCheck browser, textareaFieldSel, 'Hello', '', ( (err) -> test.done(err) )
        "23/ unbinding keypress": (test) ->
          unbind browser, textareaFieldSel, 'keypress', ( (err) -> test.done(err) )            
        "24/ typing 'Hello'": (test) -> 
          typeAndCheck browser, textareaFieldSel, 'Hello', 'Hello', ( (err) -> test.done(err) )
        "25/ clear": (test) -> 
          clearAndCheck browser, textareaFieldSel, ( (err) -> test.done(err) )      
        "26/ preventing default on keyup": (test) -> 
          preventDefault browser, textareaFieldSel, 'keyup', ( (err) -> test.done(err) )              
        "27/ typing 'Hello'": (test) -> 
          typeAndCheck browser, textareaFieldSel, 'Hello', 'Hello', ( (err) -> test.done(err) )
        "28/ unbinding keypress": (test) ->
          unbind browser, textareaFieldSel, 'keyup', ( (err) -> test.done(err) )      
        "30/ clear": (test) -> 
          clearAndCheck browser, textareaFieldSel, ( (err) -> test.done(err) )      
        "31/ adding alt key tracking": (test) ->         
          altKeyTracking browser, textareaFieldSel, ( (err) -> test.done(err) )   
        "32/ typing ['a']": (test) -> 
          typeAndCheck browser, textareaFieldSel, ['a'], 'altKey off', ( (err) -> test.done(err) )
        "33/ typing [altKey,nullKey,'a']": (test) -> 
          typeAndCheck browser, textareaFieldSel, [altKey,nullKey,'a'], 'altKey off', ( (err) -> test.done(err) )
        "34/ typing [altKey,'a']": (test) -> 
          typeAndCheck browser, textareaFieldSel, [altKey,'a'], 'altKey on', ( (err) -> test.done(err) )
        "35/ typing ['a']": (test) -> 
          typeAndCheck browser, textareaFieldSel, ['a'], 'altKey off', ( (err) -> test.done(err) )
        "36/ clear": (test) -> 
          clearAndCheck browser, textareaFieldSel, ( (err) -> test.done(err) )   
        "37/ typing [nullKey]": (test) -> 
          typeAndCheck browser, textareaFieldSel, [nullKey], '', ( (err) -> test.done(err) )
        "38/ typing ['a']": (test) -> 
          keysAndCheck browser, textareaFieldSel, ['a'], 'altKey off', ( (err) -> test.done(err) )        
        "39/ clear": (test) -> 
          clearAndCheck browser, textareaFieldSel, ( (err) -> test.done(err) )   
        "40/ unbinding keydown": (test) ->
          unbind browser, textareaFieldSel, 'keydown', ( (err) -> test.done(err) )      

      "keys":
        "1/ typing nothing": (test) -> 
          keysAndCheck browser, textareaFieldSel, "", "", ( (err) -> test.done(err) )
        "2/ typing []": (test) -> 
          keysAndCheck browser, textareaFieldSel, [], "", ( (err) -> test.done(err) )
        "3/ typing 'Hello'": (test) -> 
          keysAndCheck browser, textareaFieldSel, 'Hello', 'Hello', ( (err) -> test.done(err) )
        "4/ clear": (test) -> 
          clearAndCheck browser, textareaFieldSel, ( (err) -> test.done(err) )
        "5/ typing ['Hello']": (test) -> 
          keysAndCheck browser, textareaFieldSel, ['Hello'], 'Hello', ( (err) -> test.done(err) )
        "6/ clear": (test) -> 
          clearAndCheck browser, textareaFieldSel, ( (err) -> test.done(err) )
        "7/ typing ['Hello',' ','World','!']": (test) -> 
          keysAndCheck browser, textareaFieldSel, ['Hello',' ','World','!'], 'Hello World!', ( (err) -> test.done(err) )
        "8/ clear": (test) -> 
          clearAndCheck browser, textareaFieldSel, ( (err) -> test.done(err) )
        "9/ typing 'Hello\\n'": (test) -> 
          keysAndCheck browser, textareaFieldSel, 'Hello\n', 'Hello\n', ( (err) -> test.done(err) )      
        "10/ typing '\\r'": (test) -> 
          keysAndCheck browser, textareaFieldSel, '\r', 'Hello\n\r', ( (err) -> test.done(err) )
        "11/ typing [returnKey]": (test) -> 
          keysAndCheck browser, textareaFieldSel, [returnKey], 'Hello\n\r\r', ( (err) -> test.done(err) )      
        "13/ typing [enterKey]": (test) -> 
          keysAndCheck browser, textareaFieldSel, [enterKey], 'Hello\n\r\r\r', ( (err) -> test.done(err) )
        "14/ typing ' World!'": (test) -> 
          keysAndCheck browser, textareaFieldSel, ' World!', 'Hello\n\r\r\r World!', ( (err) -> test.done(err) )
        "15/ clear": (test) -> 
          clearAndCheck browser, textareaFieldSel, ( (err) -> test.done(err) )      
        "16/ preventing default on keydown": (test) -> 
          preventDefault browser, textareaFieldSel, 'keydown', ( (err) -> test.done(err) )      
        "17/ typing 'Hello'": (test) -> 
          keysAndCheck browser, textareaFieldSel, 'Hello', '', ( (err) -> test.done(err) )      
        "18/ unbinding keydown": (test) ->
          unbind browser, textareaFieldSel, 'keydown', ( (err) -> test.done(err) )      
        "19/ typing 'Hello'": (test) -> 
          keysAndCheck browser, textareaFieldSel, 'Hello', 'Hello', ( (err) -> test.done(err) )
        "20/ clear": (test) -> 
          clearAndCheck browser, textareaFieldSel, ( (err) -> test.done(err) )      
        "21/ preventing default on keypress": (test) -> 
          preventDefault browser, textareaFieldSel, 'keypress', ( (err) -> test.done(err) )      
        "22/ typing 'Hello'": (test) -> 
          keysAndCheck browser, textareaFieldSel, 'Hello', '', ( (err) -> test.done(err) )
        "23/ unbinding keypress": (test) ->
          unbind browser, textareaFieldSel, 'keypress', ( (err) -> test.done(err) )            
        "24/ typing 'Hello'": (test) -> 
          keysAndCheck browser, textareaFieldSel, 'Hello', 'Hello', ( (err) -> test.done(err) )
        "25/ clear": (test) -> 
          clearAndCheck browser, textareaFieldSel, ( (err) -> test.done(err) )      
        "26/ preventing default on keyup": (test) -> 
          preventDefault browser, textareaFieldSel, 'keyup', ( (err) -> test.done(err) )              
        "27/ typing 'Hello'": (test) -> 
          keysAndCheck browser, textareaFieldSel, 'Hello', 'Hello', ( (err) -> test.done(err) )
        "28/ unbinding keypress": (test) ->
          unbind browser, textareaFieldSel, 'keyup', ( (err) -> test.done(err) )      
        "30/ clear": (test) -> 
          clearAndCheck browser, textareaFieldSel, ( (err) -> test.done(err) )              
        "31/ adding alt key tracking": (test) ->         
          altKeyTracking browser, textareaFieldSel, ( (err) -> test.done(err) )   
        "32/ typing ['a']": (test) -> 
          keysAndCheck browser, textareaFieldSel, ['a'], 'altKey off', ( (err) -> test.done(err) )        
        "33/ typing [altKey,nullKey,'a']": (test) -> 
          keysAndCheck browser, textareaFieldSel, [altKey,nullKey,'a'], 'altKey off', ( (err) -> test.done(err) )
        "34/ typing [altKey,'a']": (test) -> 
          keysAndCheck browser, textareaFieldSel, [altKey,'a'], 'altKey on', ( (err) -> test.done(err) )
        "35/ typing ['a']": (test) -> 
          keysAndCheck browser, textareaFieldSel, ['a'], 'altKey on', ( (err) -> test.done(err) )
        "36/ clear": (test) -> 
          clearAndCheck browser, textareaFieldSel, ( (err) -> test.done(err) )   
        "37/ typing [nullKey]": (test) -> 
          keysAndCheck browser, textareaFieldSel, [nullKey], '', ( (err) -> test.done(err) )
        "38/ typing ['a']": (test) -> 
          keysAndCheck browser, textareaFieldSel, ['a'], 'altKey off', ( (err) -> test.done(err) )        
        "39/ clear": (test) -> 
          clearAndCheck browser, textareaFieldSel, ( (err) -> test.done(err) )   
        "40/ unbinding keydown": (test) ->
          unbind browser, textareaFieldSel, 'keydown', ( (err) -> test.done(err) )      
 
     
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
