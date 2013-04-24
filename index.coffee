path = require 'path'

{AustLII} = require './austlii'

tmp = (p) -> path.join __dirname, 'tmp', p

run = (done) ->

  # 1. Get list of all principal acts of parliament.

  AustLII.saveConsolidatedActs tmp('acts.json'), {first: 1}, (e, acts) ->
    return done e if e
    done()

  # 2. Download bill series for each act of parliament.

run (e) ->
  throw e if e
  console.log 'Success'


# TODO: For each principal act, find amendments currently before parliament.
