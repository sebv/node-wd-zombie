# Element class
# Wrapper around browser methods

class Element
  constructor: (value, browser) ->
    throw (new Error "no value passed to element constructor") unless value?
    throw (new Error "no browser passed to element constructor") unless browser?
    @value = value
    @browser = browser

  toString: ->
    String @value

  sendKeys: (keys, cb) ->
    @browser.type @value, keys, cb 

  click: (cb) ->
    @browser.clickElement @value, cb

  text: (cb) ->
    @browser.text @value, cb 

  textPresent: (searchText, cb) ->
    @browser.textPresent searchText, @value, cb

  getAttribute: (name, cb) ->
    @browser.getAttribute @value, name, cb

  getValue: (cb) ->
      @browser.getValue @value, cb

  getComputedCSS: (styleName, cb) ->
    @browser.getComputedCSS @value, styleName, cb

  clear: (cb) ->
    @browser.clear @value, cb

exports.Element = Element
