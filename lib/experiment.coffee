Browser = require "zombie"

browser = new Browser debug: true

browser.visit "http://www.google.com?a=1", (err,browser, status) ->
  throw err if err?
  browser.wait 1000

  browser.onalert (message) ->
    console.log "OKOK", message
    true

  browser.window.alert "THIS IS AN ALERT"


  #el = browser.querySelector "p"  
  #console.log "OKOK", el.textContent
  #for k,v of el
  #  console.log k, typeof v
  
###    

  browser.visit "http://www.apple.com", (err,browser, status) ->
    throw err if err?
    for k,v of browser.history
      console.log k
    console.log "browser.history.back=" + browser.history.back()
    console.log "browser.history.forward=" + browser.history.forward()
      

  console.log "title=", browser.document.title
  console.log (browser.querySelector "body #main")
  res = browser.document.getElementsByTagName "a"
  console.log res[1].textContent
  #for k,v of res[0]
  #  console.log k