fs = require 'fs'
Browser = require 'zombie'
uuid = require 'node-uuid'
protocol = {}
SPECIAL_KEYS = require "./special-keys"
SPECIAL_KEY_ARRAY = (v for k,v of SPECIAL_KEYS)
MODIFIER_KEYS = {
  nullKey: '\uE000',
  shiftKey: '\uE008',
  ctrlKey: '\uE009',
  altKey: '\uE00A',
  metaKey: '\uE03D'
}
MODIFIER_KEY_ARRAY = (v for k,v of MODIFIER_KEYS)

wait = (callback) ->
  args = []
  args.push @implicitWaiTimeout if @implicitWaiTimeout? and (@implicitWaiTimeout > 0)
  args.push callback
  @browser.wait args...

waitAfterPage = (callback) ->
  args = []
  args.push @pageLoadTimeout if @pageLoadTimeout? and (@pageLoadTimeout > 0)
  args.push callback
  @browser.wait args...

waitAfterExecute = (callback) ->
  args = []
  args.push @syncScriptTimeout if @syncScriptTimeout? and (@syncScriptTimeout > 0)
  args.push callback
  @browser.wait args...

# performOpFunc return true if finished
waitForOp = (performOpFunc, done) ->  
  # trying once
  unless(performOpFunc()) 
    #wait for result if needed
    if @implicitWaiTimeout > 0
      limit = Date.now() + @implicitWaiTimeout
      intervalId = setInterval =>     
        if(performOpFunc())
          clearInterval(intervalId);
        else if (Date.now() > limit)
          done null, null
          clearInterval(intervalId)                  
      , @pollMs
    else
      done null, null
     
newError = (opts) ->
  err = new Error
  for k,v of opts
    err[k] = v 
  err

_newModifierKeys = ->
  reset: ->
    @ctrlKey = false
    @altKey = false 
    @shiftKey = false 
    @metaKey = false
    @          
  
protocol.init = (desired, done) ->
  #@browser = new Browser debug:true
  @browser = new Browser()
  @browser.setMaxListeners(100)
  @modifierKeys = _newModifierKeys().reset()
  @implicitWaiTimeout = 0
  @syncScriptTimeout = 30000
  @asyncScriptTimeout = 0    
  @pageLoadTimeout = 0
  @pollMs = 25
  @waitTimeout = 1000
  done null, @browser

protocol.status = (done) ->
  done null, {status:'OK'}

protocol.sessions = (done) ->
  done null, {'1': {browserName:'zombie', headless:true, platform:'ANY'}}

protocol.sessionCapabilities = (done) ->
  if(@browser?)
    done null, {browserName:'zombie', headless:true, platform:'ANY'}
  else
    done newError {message:"No session."}

protocol.altSessionCapabilities = (done) ->
  if(@browser?)
    done null, {browserName:'zombie', headless:true, platform:'ANY'}
  else
    done newError {message:"No session."}
        
protocol.get = (url, done) ->
  @browser.visit url, done    
  
protocol.refresh = (done) ->
  @browser.reload done    

protocol.back = (done) ->
  @browser.window.history.back()
  waitAfterPage.apply this, [done]
  
protocol.forward = (done) ->
  @browser.window.history.forward()
  waitAfterPage.apply this, [done]
  
protocol.url = (done) ->
  done null, @browser.location.href    
  
protocol.quit = (done) ->
  @browser.windows.close(window) for window in @browser.windows.all()
  @browser = null
  done null if done?

protocol.close = (done) ->
  @browser.windows.close(@browser.windows.current)
  done null if done?

protocol.setPageLoadTimeout = (ms , done) ->
  @pageLoadTimeout = ms;
  done null

protocol.setAsyncScriptTimeout = (ms , done) ->
  @asyncScriptTimeout = ms;
  done null

protocol.setImplicitWaitTimeout = (ms , done) ->
  @implicitWaiTimeout = ms;
  done null

protocol.setSyncScriptTimeout = (ms , done) ->
  @syncScriptTimeout = ms;
  done null

protocol.setWaitTimeout = protocol.setImplicitWaitTimeout
  
protocol.eval = (code, done) ->
  res = null
  try
    res = @browser.evaluate code    
  catch err
    return done newError(
      message: 'Evaluation failure.'
      cause:err
      code: code
    )
  waitAfterExecute.apply this, [ ->          
  ]
  # the script keeps running on it's own until exec sync timeout
  # but return is immediatele 
  done null, res
    

protocol.safeEval = protocol.eval

protocol.execute = (code, args ,done) ->
  if not done? then [args, done] = [ [], args]
  script = """
  var ctx = #{JSON.stringify({code: code, args:args})};
  var f = function () {
    eval(ctx.code);
  };
  f.apply(this, ctx.args);  
  """
  res = null  
  try
    @browser.evaluate script    
  catch err
    return done newError(
      message: 'Execution failure.'
      cause:err
      code: code
      args: args
    )
  waitAfterExecute.apply this, [ ->          
  ]  
  # the script keeps running on it's own until exec sync timeout
  # but return is immediatele 
  done null, res
  
  
protocol.safeExecute = protocol.execute

protocol.executeAsync = (code, args ,done) ->
  timeout = @asyncScriptTimeout or 0
  if not done? then [args, done] = [ [], args]
  key = uuid.v4()
  script = """
  var ctx = #{JSON.stringify(
    key: key
    pollMs: @pollMs     
    code: code 
    args:args
    )};
  if(window.executeAsyncRes == null) {
    window.executeAsyncRes = {};
  };
  window.executeAsyncRes[ctx.key] = {}
  var callback = function ( res ) {
    if(window.executeAsyncRes[ctx.key]!=null) {
      window.executeAsyncRes[ctx.key].finished = true;
      window.executeAsyncRes[ctx.key].res = res; 
    }
  };
  var f = function () {
    eval(ctx.code);    
  };  
  ctx.args.push(callback);    
  f.apply(this, ctx.args);
  //triggers wait method more often
  window.executeAsyncRes[ctx.key].i = setInterval( function() {   
  }, ctx.pollMs);
  """
  execTimeout = null;
  timedOut = false;
  returned = false;
  try    
    @browser.evaluate script
  catch err
    return done newError(
      message: 'Execution failure.'
      cause:err
      code: code
      args: args
    )
  # timeout
  if timeout > 0
    execTimeout = setTimeout =>
      timedOut = true;
    , timeout
  response = null;
  # waiting  
  @browser.wait (window) =>
    response = window.executeAsyncRes[key]
    finished = (response?.finished) or timedOut    
    if finished
      window.clearInterval window.executeAsyncRes[key].i
      window.executeAsyncRes[key] = null;      
    return finished 
  , ->
    unless returned        
      clearTimeout(execTimeout) if execTimeout 
      returned = true
      if response?.finished      
        done null, response.res
      else if timedOut
        done newError {
          status: 28 
          message: "Timed out: execAsync ."
          timeout: timeout
          code: code
          args: args
        }          
      else          
        done newError(
          message: "execAsync error."
          timeout: timeout
          code: code
          args: args
        )
        
    
protocol.safeExecuteAsync = protocol.executeAsync

_querySelectorOrNull = (sel, done) ->  
  waitForOp.apply @, [ 
    =>
      res = null
      try
        res = @browser.querySelector sel
      catch err
        done err
        return true      
      done null, res if res?        
      res?      
    , done  
  ]
    
protocol.elementOrNull = (searchType, value, done) ->
  switch searchType
    when "class name" then _querySelectorOrNull.apply @, [".#{value}", done]
    when "css selector" then _querySelectorOrNull.apply @, [value, done]    
    when "id" then _querySelectorOrNull.apply @, ["##{value}", done]
    when "name" then _querySelectorOrNull.apply @, ["[name='#{value}']", done]
    when "link text", "partial link text", "tag name", "xpath"
      protocol.elements.apply this, [ searchType, value, (err, res) ->
        if err? then done err
        done null, (if res?.length > 0 then res[0] else null)
      ]
    else
      done "Search type #{searchType} not supported." 
  
protocol.element = (searchType, value, done) ->
  @elementOrNull.apply @, [
    searchType, value, (err, res) ->
      if err? then done err
      else if not res? then done status:7
      else done null, res
  ]
    
protocol.elementIfExists = (searchType, value, done) ->
  @elementOrNull.apply @, [ 
    searchType, value, (err, res) ->
      if err? then done err
      else if not res? then done null, undefined
      else done null, res
  ]

protocol.hasElement = (searchType, value, done) ->
  @elementOrNull.apply @, [
    searchType, value, (err, res) ->
      if err? then done err
      else done null, res?
  ]

_transformRes = (rawRes) ->
  i=0
  res=[]
  while rawRes[i]?
    res.push rawRes[i]
    i++
  res
  
_querySelectorAllOrNull = (sel, done) ->  
  waitForOp.apply @, [ 
    =>
      rawRes = null
      try
        rawRes = @browser.querySelectorAll sel
      catch err
        done err
        return true   
      res = _transformRes rawRes if rawRes?
      done null, res if res?.length >0
      (res?.length >0)
    , done
  ]

protocol.elements = (searchType, value, done) ->
  # returning empty array instead of null
  _done = done
  done = (err, res) ->
    res = [] unless res?
    _done err, res
    
  switch searchType  
    when "class name" then _querySelectorAllOrNull.apply this, [".#{value}", done]
    when "css selector" then _querySelectorAllOrNull.apply this, [ value, done]
    when "id" then _querySelectorAllOrNull.apply this, ["##{value}", done]
    when "name" then _querySelectorAllOrNull.apply this, ["[name='#{value}']", done]
    when "link text" 
      waitForOp.apply @, [
        =>
          rawRes = null;
          try
            rawRes = @browser.document.getElementsByTagName 'a'
          catch err
            done err
            return true
          res = (val for val in (_transformRes rawRes) \
            when val.textContent is value)
          done null, res if (res?.length > 0)
          (res?.length > 0)
        , done
      ]
    when "partial link text" 
      waitForOp.apply @, [
        =>
          rawRes = null;
          try
            rawRes = @browser.document.getElementsByTagName 'a'
          catch err
            done err
            return true
          res = (val for val in (_transformRes rawRes) \
            when (val.textContent?.indexOf value) >= 0)
          done null, res if (res?.length > 0)
          (res?.length > 0)
        , done
      ]
    when "tag name" 
      waitForOp.apply @, [
        =>
          rawRes = null;
          try
            rawRes = @browser.document.getElementsByTagName value
          catch err
            done err
            return true
          res = _transformRes rawRes        
          done null, res if (res?.length > 0)
          (res?.length > 0)
        , done
      ]
    when "xpath" 
      waitForOp.apply @, [
        =>
          rawRes = null;
          try
            rawRes = @browser.xpath value
          catch err
            done err
            return true
          res = (val for val in rawRes.value)     
          done null, res if (res?.length > 0)
          (res?.length > 0)
        , done
      ]
    else
      done "Search type #{searchType} not supported." 

# convert to type to something like ById, ByCssSelector, etc...
elFuncSuffix = (type) ->
  res = (" by " + type).replace(/(\s[a-z])/g, ($1) ->
    $1.toUpperCase().replace " ", ""
  )
  res.replace "Xpath", "XPath"

# return correct jsonwire type
elFuncFullType = (searchType) ->
  return "css selector"  if searchType is "css"
  searchType

# from JsonWire spec + shortcuts    
elementFuncTypes = [ "class name", "css selector", "id", "name", "link text", "partial link text", "tag name", "xpath", "css" ]

for _searchType in elementFuncTypes
  do ->
    searchType = _searchType
    protocol["element" + (elFuncSuffix searchType) ] = (value, cb) ->
      protocol.element.apply this, [(elFuncFullType searchType), value, cb]
  
    protocol["element" + (elFuncSuffix searchType) + "OrNull" ] = (value, cb) ->
      protocol.elementOrNull.apply this, [(elFuncFullType searchType), value, cb]

    protocol["element" + (elFuncSuffix searchType) + "IfExists" ] = (value, cb) ->
      protocol.elementIfExists.apply this, [(elFuncFullType searchType), value, cb]

    protocol["hasElement" + (elFuncSuffix searchType) ] = (value, cb) ->
      protocol.hasElement.apply this, [(elFuncFullType searchType), value, cb]

    protocol["elements" + (elFuncSuffix searchType) ] = (value, cb) ->
      protocol.elements.apply this, [(elFuncFullType searchType), value, cb]
  
protocol.getAttribute = (element, attrName, done) ->  
  waitForOp.apply @, [
    =>
      attrValue = null;
      try      
        attrValue = element.getAttribute attrName if element.hasAttribute attrName
      catch err
        done newError {
          message: "Cannot get attribute #{attrName}."
          element: element 
          attrName: attrName     
          cause: err
        }
        return true
      done null, attrValue if attrValue?
      attrValue?
    , done
  ]

protocol.getValue = (element, done) ->  
  waitForOp.apply @, [
    =>
      value = null;
      try  
        value = element.value
      catch err
        done newError {
          message: "Cannot get value."
          element: element 
          cause: err
        }
        return true
      done null, value if value?
      value?
    , done
  ]

_rawText = (element, done) ->  
  waitForOp.apply @, [
    =>
      value = null
      try  
        value = element.textContent
      catch err
        done newError {
          message: "Cannot get text."
          element: element 
          cause: err
        }
        return true
      done null, value if value?
      value?
    , done
  ]
  
protocol.text = (element, done) ->
  if (not element?) or (element is 'body')
    protocol.elementByTagName.apply this, ['body', (err, rootEl) ->
      return done err if err?
      _rawText.apply this , [rootEl, done]
    ]
  else
    _rawText.apply this , [element, done]

protocol.textPresent = (text ,element, done) ->  
  protocol.text.apply this, [element, (err, elText) ->
    return done err if err?
    res = (elText?.indexOf text) >= 0
    done null, res
  ]
  
protocol.clickElement = (element, done) ->
  @browser.fire "click", element, (err) =>
    if(err?) then return done err    
    @browser.document.active = element
    done null  
  
protocol.moveTo = (element, args...,done) ->
  # position arguments not yet supported    
  @browser.fire "mousemove", element, (err) =>
    if(err?) then return done err
    # trigerring mouseover
    evObj = @browser.document.createEvent 'MouseEvents'
    evObj.initEvent 'mouseover', true, false
    element.dispatchEvent evObj
    # setting active
    @browser.document.active = element    
    done null  

protocol.active = (done) ->
  res = null;
  try
    res = @browser.document.active
  catch err
    if(err?) then return done err
  done null, res

protocol.buttonDown = (done) ->
  activeEl = @browser.document.active
  @browser.fire "mousedown", activeEl, (err) =>
    if(err?) then return done err
    done null  

protocol.buttonUp = (done) ->
  activeEl = @browser.document.active
  @browser.fire "mouseup", activeEl, (err) =>
    if(err?) then return done err
    done null  

protocol.click = (args..., done) ->
  button = args?[0]
  button = 0 unless button?
  activeEl = @browser.document.active
  evObj = @browser.document.createEvent 'MouseEvents'
  evObj.initEvent 'click', true, false  
  evObj.button = button    
  activeEl .dispatchEvent evObj
  evObj = @browser.document.createEvent 'MouseEvents'
  evObj.initEvent 'mousedown', true, false  
  evObj.button = button    
  activeEl .dispatchEvent evObj
  evObj = @browser.document.createEvent 'MouseEvents'
  evObj.initEvent 'mouseup', true, false  
  evObj.button = button    
  activeEl .dispatchEvent evObj
  wait.apply this, [done]  

protocol.doubleclick = (done) ->
  activeEl = @browser.document.active
  # trigerring mouseover
  evObj = @browser.document.createEvent 'MouseEvents'
  evObj.initEvent 'dblclick', true, false
  activeEl .dispatchEvent evObj
  wait.apply this, [done]  


_rawType = (element, texts, done) ->
  if not(texts instanceof Array) then texts = [texts]
  for text in texts
    for char in text
      do =>
        charCode = null;
        virtualKeyCode = null;
        if(char in MODIFIER_KEY_ARRAY)
          modifKeyName = null;
          (modifKeyName = k for k,v of MODIFIER_KEYS when v is char)
          if(modifKeyName is 'nullKey')
            @modifierKeys.reset()
          else
            @modifierKeys[modifKeyName] = not(@modifierKeys[modifKeyName])
        else 
          if(char in SPECIAL_KEY_ARRAY)
            virtualKeyCode = char;
          else
            charCode = char.charCodeAt()          
            element.value = element.value + char
          for eventType in ['keydown', 'keypress', 'keyup']
            do =>              
              evObj = @browser.document.createEvent "UIEvents"
              evObj.initEvent eventType, true, true
              evObj.view = @browser.window
              evObj.altKey = @modifierKeys.altKey
              evObj.ctrlKey = @modifierKeys.ctrlKey
              evObj.shiftKey = @modifierKeys.shiftKey
              evObj.metaKey = @modifierKeys.metaKey
              evObj.keyCode = virtualKeyCode
              evObj.charCode = charCode
              element.dispatchEvent evObj
  done null
  
protocol.type = (element, texts, done) ->
  if not(texts instanceof Array) then texts = [texts]
  @modifierKeys.reset()
  _rawType.apply this , [ element, texts, (err) =>
    return done err if err?
    @modifierKeys.reset()
    wait.apply this, [done]
  ]

protocol.keys = (texts, done) ->  
  if not(texts instanceof Array) then texts = [texts]
  element = @browser.document.active
  _rawType.apply this , [ element, texts, (err) =>
    return done err if err?
    wait.apply this, [done]
  ]

protocol.clear = (element, done) ->
  try 
    element.value = ''
  catch err
    return done err if err?
  done null  

protocol.title = (done) ->
  title = null
  try 
    title = @browser.document.title    
  catch err
    return done err if err?
  done null, title  
  
protocol.dismissAlert = (done) ->
  # alert don't seem to be persistent
  done null

protocol.acceptAlert = (done) ->
  # alert don't seem to be persistent
  done null

protocol.deleteAllCookies = (done) ->
  try 
    @browser.cookies().clear()    
  catch err
    return done err if err?
  done null 

convertCookie = (rawCookie) ->
  cookie = {}
  for k,v of rawCookie when v isnt 'function'
    newKey = if k is 'key' then 'name' else k
    cookie[newKey] = v
  cookie
   
protocol.allCookies = (done) ->
  rawCookies = null
  try 
    rawCookies = @browser.cookies().all()    
  catch err
    return done err if err?
  cookies = (convertCookie rawCookie for rawCookie in rawCookies)
  done null, cookies

protocol.setCookie = (cookie, done) ->
  pathArgs = []
  pathArgs.push cookie.domain 
  pathArgs.push cookie.path if cookie.path?
  cookieArgs = [cookie.name, cookie.value]
  extra = {}
  extra[k] = v for k,v of cookie when k not in ['domain','path','name','value']
  cookieArgs.push extra unless (k for k,v of extra).length is 0
  try    
    (@browser.cookies pathArgs...).set cookieArgs...
  catch err
    return done err if err?
  done null

protocol.deleteCookie = (name, done) ->
  try 
    @browser.cookies().remove name    
  catch err
    return done err if err?
  done null
   
waitForConditionImpl = (conditionExpr, limit, poll, cb) ->
  _this = this
  if Date.now() < limit
    protocol.safeEval.apply _this, [ conditionExpr, (err, res) ->
      return cb(err)  if err?
      if res is true
        cb null, true
      else
        setTimeout ->
          waitForConditionImpl.apply _this, [ conditionExpr, limit, poll, cb ]
        , poll
    ]
  else
    protocol.safeEval.apply _this, [ conditionExpr, (err, res) ->
      return cb(err)  if err?
      if res is true
        cb null, true
      else
        cb "waitForCondition failure for: " + conditionExpr
     ]

# (conditionExpr, timeout, poll, cb)
# timeout and poll are optional
protocol.waitForCondition = (conditionExpr, args... , cb) ->
  [timeout, poll] = args

  timeout = timeout or @waitTimeout
  poll = poll or @pollMs
  limit = Date.now() + timeout
  waitForConditionImpl.apply this, [ conditionExpr, limit, poll, cb ]

# (conditionExpr, timeout, poll, cb)
# timeout and poll are optional
waitForConditionInBrowserJsScript = fs.readFileSync(__dirname + "/browser-scripts/wait-for-cond-in-browser.js", "utf8")
protocol.waitForConditionInBrowser = (conditionExpr, args..., cb) ->
  [timeout, poll] = args

  timeout = timeout or @pollMs
  poll = poll or @pollMs
  protocol.safeExecuteAsync.apply @, [ waitForConditionInBrowserJsScript, [ conditionExpr, timeout, poll ], (err, res) ->
    return cb(err)  if err?
    return cb("waitForConditionInBrowser failure for: " + conditionExpr)  unless res is true
    cb null, res
   ]  

module.exports = protocol
