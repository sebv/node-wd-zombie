# wd-zombie

wd headless twin.

wd-zombie is an re-implementation of the [wd](https://github.com/admc/wd) interface using 
[zombie](https://github.com/assaf/zombie).  

## usage

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

Interface identical to [wd](https://github.com/admc/wd).

