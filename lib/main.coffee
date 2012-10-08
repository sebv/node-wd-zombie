Webdriver = require("./webdriver")
SPECIAL_KEYS = require("./special-keys")

exports.remote = ->
  new Webdriver
  
exports.SPECIAL_KEYS = SPECIAL_KEYS
