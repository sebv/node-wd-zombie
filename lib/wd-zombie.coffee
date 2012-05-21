EventEmitter = require("events").EventEmitter
protocol = require("./protocol")
SPECIAL_KEYS = require("./special-keys")

class Webdriver extends EventEmitter
  constructor: ->
    @browser = null
    
wrap = (f) ->
  (args...) ->
    f.apply this, args

for k,v of protocol
  Webdriver::[k] = wrap(v)  if typeof v is "function"

exports.remote = ->
  new Webdriver
  
exports.SPECIAL_KEYS = SPECIAL_KEYS
