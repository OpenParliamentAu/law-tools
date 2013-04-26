require 'coffee-trace'
path = require 'path'
_ = require 'underscore'
async = require 'async'
fs = require 'fs'

{AustLII} = require 'austlii'
{ComLaw} = require 'comlaw-scraper'

getUserHome = -> process.env.HOME or process.env.HOMEPATH or process.env.USERPROFILE
workDir = path.join getUserHome(), 'tmp/main'
tmp = (p) -> path.join workDir, p

# Save a file containing all consolidated acts with ComLawIds.
getAllActSeriesWithComLawIds = (opts, done) ->
  _.defaults opts,
    pagesOfActSeries: null
    noOfActSeries: null
    force: false

  # 1. Get list of all principal acts of parliament.
  # DEBUG: Currently getting only first page (Bills starting with `A`).
  await AustLII.saveConsolidatedActs tmp('actSeries.json'),
    first: opts.consolidatedActPages
    force: opts.force
  , defer e, actSeries
  return done e if e

  # 2. Download bill series for each act of parliament.
  if opts.noOfActSeries?
    actSeries = _.first actSeries, opts.noOfActSeries
    
  for act in actSeries
    # Skip if we already have the id for this act series.
    unless act.comLawId?
      # Find bill series web page by act name.
      await ComLaw.getComLawIdFromActTitle act.title, defer e, id
      return done e if e
      unless id?
        act.comLawId = null
        return done 'Could not find ComLawId from act name'
      act.comLawId = id

  fs.writeFileSync tmp('actSeries.json'), JSON.stringify(actSeries, null, 2)
  done null, actSeries

# Download act series for `comLawId`.
step2 = (comLawId, opts, done) ->
  _.defaults opts,
    first: null
    force: false

  ComLaw.downloadActSeriesAndConvertToMarkdown comLawId, workDir,
    first: opts.first
    force: opts.force
  , (e, acts) ->
    cb e, acts

step3 = (comLawId) ->
  opts = {}
  ComLaw.downloadActSeries comLawId, workDir, opts, (e, acts, manifestDest, baseDir) ->

step4 = (done) ->
  ComLaw.convertActsToMarkdown acts, manifestDest, baseDir, done

run = (done) ->
  step1
    consolidatedActPages: 1
    noOfActSeries: 1
    force: true
  , (e, actSeries) ->
    async.eachSeries actSeries, (cb) ->
      return cb() unless actSeries.comLawId?
      step2
        first: 2
        force: true
      , actSeries.comLawId, cb
    , (e) ->
      return done e if e
      done()

await getAllActSeriesWithComLawIds
  consolidatedActPages: 1
  noOfActSeries: 1
  force: true
, defer e
throw e if e
console.log 'Success'

#run (e) ->
#  throw e if e
#  console.log 'Success'

# TODO: For each principal act, find amendments currently before parliament.
