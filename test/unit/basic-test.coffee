# nodeunit test
leakDetector = (require '../common/leak-detector')()

{runTestWith} = require '../common/basic-test-base'

exports.wd =
  'basic test':
    
    zombie: (runTestWith {}, {browserName:'zombie'})
    
    'checking leaks': leakDetector.lookForLeaks

