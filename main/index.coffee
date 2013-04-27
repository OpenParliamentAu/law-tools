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
actSeriesManifestPath = tmp('actSeriesCollection.json')

saveActSeriesToFile = (actSeries) ->
  fs.writeFileSync actSeriesManifestPath, JSON.stringify(actSeries, null, 2)

# Save a file containing all consolidated acts with ComLawIds.
getAllActSeriesWithTheirComLawIds = (opts, done) ->
  _.defaults opts,
    actSeriesStartingWithLetter: null
    noOfActSeriesToProcess: null
    force: false

  # 1. Get list of all principal acts of parliament.
  # DEBUG: Currently getting only first page (Bills starting with `A`).
  await AustLII.saveConsolidatedActs actSeriesManifestPath,
    letter: opts.actSeriesStartingWithLetter
    force: opts.force
  , defer e, actSeriesCollection
  return done e if e

  # 2. Download bill series for each act of parliament.
  if opts.noOfActSeriesToProcess?
    actSeriesCollection = _.first actSeriesCollection, opts.noOfActSeriesToProcess

  for actSeries in actSeriesCollection
    # Skip if we already have the id for this act series.
    unless actSeries.comLawId?
      # Find bill series web page by act name.
      await ComLaw.getComLawIdFromActTitle actSeries.title, defer e, id
      return done e if e
      unless id?
        actSeries.comLawId = null
        return done 'Could not find ComLawId from act name'
      actSeries.comLawId = id

  saveActSeriesToFile actSeriesCollection
  done null, actSeriesCollection

# Download act series for `comLawId`.
downloadFilesForEachActInActSeries = (comLawId, workDir, opts, done) ->
  _.defaults opts,
    first: null
    force: false
  ComLaw.downloadActSeries comLawId, workDir,
    first: opts.first
    force: opts.force
  , done

run = (workDir, done) ->

  await getAllActSeriesWithTheirComLawIds
    actSeriesStartingWithLetter: 'a'
    noOfActSeriesToProcess: 2
    force: false
  , defer e, actSeriesCollection

  for actSeries in actSeriesCollection
    if actSeries.comLawId?
      await downloadFilesForEachActInActSeries actSeries.comLawId, workDir,
        {first: 2, force: true}
      , defer e, acts, manifestDest, baseDir
      actSeries.manifestFile = manifestDest
      actSeries.baseDir = baseDir
      return done e if e

  saveActSeriesToFile actSeriesCollection

  return # DEBUG

  for actSeries in actSeriesCollection
    await ComLaw.convertActsToMarkdown acts, actSeries.manifestFile
    , actSeries.baseDir, defer e
    return done e if e

  done()

await run workDir, defer e
throw e if e
console.log 'Success'

# TODO: For each principal act, find amendments currently before parliament.
