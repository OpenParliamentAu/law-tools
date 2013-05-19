Model = require('./model')()
errTo = require 'errto'

class @DB

  dropAndSync: (done) ->
    await Model.dropAndSync errTo done, defer()
    done()
