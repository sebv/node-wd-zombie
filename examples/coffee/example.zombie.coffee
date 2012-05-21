webdriver = null
try
  webdriver = require("wd-zombie")
catch err
  webdriver = require("../../lib/wd-zombie")
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
            