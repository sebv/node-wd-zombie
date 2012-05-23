HTML = require("jsdom").dom.level3.html

PRINTABLE_VIRTUAL_KEYS = {
  'Back space': 8,
  'Tab': 9,
  'Clear': 12,
  'Return': 13,
  'Space': 32,
};

PRINTABLE_VIRTUAL_KEY_ARRAY = (v for k,v of PRINTABLE_VIRTUAL_KEYS)

SUBMIT_VIRTUAL_KEYS = {
  'Return': 13,
  'Enter': 14,
};
SUBMIT_VIRTUAL_KEY_ARRAY = (v for k,v of SUBMIT_VIRTUAL_KEYS)

SUBMIT_CHAR_CODE_ARRAY = ['\n','\r']

# KEYDOWN trigger KEYPRES
triggerKeypress = (e) -> 
  document = e.target.ownerDocument  
  evObj = document.createEvent "UIEvents"
  evObj.initEvent 'keypress', true, true
  evObj.view = e.view
  evObj.altKey = e.altKey
  evObj.ctrlKey = e.ctrlKey
  evObj.shiftKey = e.shiftKey
  evObj.metaKey = e.metaKey
  evObj.keyCode = e.keyCode
  evObj.charCode = e.charCode
  e.target.dispatchEvent evObj

HTML.HTMLInputElement.prototype._eventDefaults.keydown = (e) ->  
  triggerKeypress(e)

HTML.HTMLTextAreaElement.prototype._eventDefaults.keydown = (e) ->  
  triggerKeypress(e)

# KEYPRESS write the text 

HTML.HTMLInputElement.prototype._eventDefaults.keypress = (e) ->  
  if (e.charCode in SUBMIT_CHAR_CODE_ARRAY) or (e.keyCode in SUBMIT_VIRTUAL_KEY_ARRAY )
    e.target.form?.submit()
  else if e.keyCode in PRINTABLE_VIRTUAL_KEY_ARRAY 
    e.target.value = e.target.value + String.fromCharCode(e.keyCode)
  else if e.charCode?
    e.target.value = e.target.value + String.fromCharCode(e.charCode)    

HTML.HTMLTextAreaElement.prototype._eventDefaults.keypress = (e) ->  
  if (e.charCode in SUBMIT_CHAR_CODE_ARRAY) or (e.keyCode in SUBMIT_VIRTUAL_KEY_ARRAY )
    e.target.form?.submit()
  else if e.keyCode in PRINTABLE_VIRTUAL_KEY_ARRAY 
    e.target.value = e.target.value + String.fromCharCode(e.keyCode)
  else if e.charCode?
    e.target.value = e.target.value + String.fromCharCode(e.charCode)    
