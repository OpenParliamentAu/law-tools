path = require 'path'
_ = require 'underscore'

{AustLII} = require '../austlii'

tmp = (p) -> path.join __dirname, 'tmp', p

run = (done) ->

  # 1. Get list of all principal acts of parliament.
  AustLII.saveConsolidatedActs tmp('acts.json'), {first: 1}, (e, acts) ->
    return done e if e

    # 2. Download bill series for each act of parliament.
    _.each acts, (act) ->
      # Find bill series page by act name.
      ComLaw.getComLawIdFromActName act.name, (e, id) ->
        return done e if e
        console.log id
        done()

run (e) ->
  throw e if e
  console.log 'Success'


# TODO: For each principal act, find amendments currently before parliament.
