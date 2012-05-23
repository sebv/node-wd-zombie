# wd-zombie

wd headless twin.

wd-zombie is a [wd](https://github.com/admc/wd) API implementation using 
[zombie](https://github.com/assaf/zombie).  

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

### extra methods

*  retrieve the zombie browser object: 
  zombieBrowser(done) -> done(err, browser) 

## test

cake test

