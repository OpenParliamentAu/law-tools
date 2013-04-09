nodeio = require 'node.io'

class Hello extends nodeio.JobClass
  input: false
  run: (num) -> @emit 'Hello World!'

@class = Hello
@job = new Hello
