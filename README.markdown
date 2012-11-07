# wd-zombie [![Build Status](https://secure.travis-ci.org/sebv/node-wd-zombie.png?branch=master)](http://travis-ci.org/sebv/node-wd-zombie)


wd headless twin.

wd-zombie is a partial [wd](https://github.com/admc/wd) API implementation using 
[zombie](https://github.com/assaf/zombie). 

Note:
  - This is only worth using for simple pages, not relying heavily on Javacripts.   
  - This package wont be maintained/improved, at least until Zombie 2 is stable. 

## usage

### CoffeeScript

```coffeescript
webdriver = require("wd-zombie")
assert = require("assert")

browser = webdriver.remote()

browser.init browserName: "zombie", ->
  browser.get "http://saucelabs.com/test/guinea-pig", ->
    browser.title (err, title) ->
      assert.ok ~title.indexOf("I am a page title - Sauce Labs"), "Wrong title!"
      browser.elementById "submit", (err, el) ->
        browser.clickElement el, ->
          browser.eval "window.location.href", (err, title) ->
            console.log "Got title:" + title
            assert.ok ~title.indexOf("#"), "Wrong title!"
            browser.quit()            
```

### JavaScript

```javascript
var webdriver = require('wd-zombie');
var assert = require('assert');

var browser = webdriver.remote();

browser.init({
    browserName:'zombie'
  }, function() {

  browser.get("http://saucelabs.com/test/guinea-pig", function() {
    browser.title(function(err, title) {
      assert.ok(~title.indexOf('I am a page title - Sauce Labs'), 'Wrong title!');
      browser.elementById('submit', function(err, el) {
        browser.clickElement(el, function() {
          browser.eval("window.location.href", function(err, title) {
            console.log("Got title:" + title); 
            assert.ok(~title.indexOf('#'), 'Wrong title!');
            browser.quit()
          })
        })
      })
    })
  })
})

```
## doc

### wd methods

API identical to [wd](https://github.com/admc/wd).

### missing wd methods

####


- getComputedCss
- takeScreenshot
- isVisible
- waitForElement
- waitForVisible

####

- all the window + frame methods

####

- element.getTagName
- element.isDisplayed
- element.getComputedCss
- element.getValue

####

- waitForElementByClassName
- waitForElementByCssSelector
- waitForElementById
- waitForElementByName
- waitForElementByLinkText
- waitForElementByPartialLinkText
- waitForElementByTagName
- waitForElementByXPath
- waitForElementByCss

####

- waitForVisibleByClassName
- waitForVisibleByCssSelector
- waitForVisibleById
- waitForVisibleByName
- waitForVisibleByLinkText
- waitForVisibleByPartialLinkText
- waitForVisibleByTagName
- waitForVisibleByXPath
- waitForVisibleByCss



### extra methods

*  retrieve the zombie browser object: 
  zombieBrowser(done) -> done(err, browser) 

## test
once: cake prepare:test

then: cake test

