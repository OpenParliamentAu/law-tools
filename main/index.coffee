path = require 'path'
_ = require 'underscore'

{AustLII} = require 'austlii'
{ComLaw} = require 'comlaw-scraper'

getUserHome = -> process.env.HOME or process.env.HOMEPATH or process.env.USERPROFILE
workDir = path.join getUserHome(), 'tmp/main'
tmp = (p) -> path.join workDir, p

run = (done) ->

  # 1. Get list of all principal acts of parliament.
  # DEBUG: Currently getting only first page (Bills starting with `A`).
  AustLII.saveConsolidatedActs tmp('acts.json'), {first: 1}, (e, actSeries) ->
    return done e if e

    # 2. Download bill series for each act of parliament.
    actSeries = _.first actSeries, 1 # DEBUG: Only one act.
    async.eachSeries actSeries, (act, cb) ->
      # Find bill series web page by act name.
      ComLaw.getComLawIdFromActTitle actSeries.title, (e, id) ->
        return done e if e
        unless id? then return done('Could not find ComLawId from act name')
        ComLaw.downloadActSeriesAndConvertToMarkdown id, workDir, {first: 2}, (e, acts) ->
          cb e, acts
    , (e) ->
      return done e if e
      done()

run (e) ->
  throw e if e
  console.log 'Success'

# TODO: For each principal act, find amendments currently before parliament.
