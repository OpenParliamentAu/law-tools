path = require 'path'

{AustLII} = require '../index'

# Download names of consolidated acts for letter A.
AustLII.saveConsolidatedActs path.join(__dirname, 'tmp/acts.json'),
  first: 1
, (e) ->
  throw e if e
  console.log 'Downloaded consolidated act names to', opts.dest
