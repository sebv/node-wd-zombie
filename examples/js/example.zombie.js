var webdriver;
try {
  webdriver = require('wd-zombie');
} catch( err ) { 
  webdriver = require('../../lib/wd-zombie');
}
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
