#require 'coffee-trace'

# Logging.
onelog = require 'onelog'
log4js = require 'log4js'
onelog.use onelog.Log4js, methods: 'setLevel'
log4js.setGlobalLogLevel 'DEBUG'
logger = onelog.get('Main')

# Vendor.
path = require 'path'
_ = require 'underscore'
async = require 'async'
fs = require 'fs'
colors = require 'colors'
wrench = require 'wrench'

# Libs.
{AustLII} = require 'austlii'
{ComLaw} = require 'comlaw-scraper'
{Util} = require 'op-util'
{Git} = require 'git-tools'

# Helpers
# -------

workDir = path.join Util.getUserHome(), 'tmp/main'
tmp = (p) -> path.join workDir, p
actSeriesManifestPath = tmp('actSeriesCollection.json')

saveActSeriesToFile = (actSeries) ->
  fs.writeFileSync actSeriesManifestPath, JSON.stringify(actSeries, null, 2)

loadActSeries = ->
  if fs.existsSync actSeriesManifestPath
    require actSeriesManifestPath
  else
    null

readManifest = (manifestDest) ->
  return null unless manifestDest?
  if fs.existsSync manifestDest
    require manifestDest
  else
    null

# Configure Logging
# -----------------

log4js.configure
  appenders: [
    {
      # Log to console.
      type: 'console'
      layout:
        type: 'pattern'
        pattern: '%m'
    },
    {
      # Log BasePage TRACE to file for bug.
      type: 'logLevelFilter'
      level: 'TRACE'
      appender:
        category: 'BasePage'
        type: 'file'
        filename: path.join workDir, 'main.log'
        layout:
          type: 'messagePassThrough'
    }
  ]
  levels:
    BasePage: 'DEBUG'


class @FederalLawScraper

  # We split the scraping process into separate steps and create JSON
  # files to store meta-data and file locations at each step. We call
  # these files **manifest** files.

  # First we get a list of all current consolidated acts from AustLII.
  #
  # We then search on ComLaw to retrieve the id of the principal act
  # for each consolidated act.
  #
  # We need the principal act id to be able to conveniently find it's
  # **series**.
  #
  # We are then left with a collection of all act series.
  #
  # Running time is ~15 minutes.

  @phase1: (done) ->
    logger.info 'Phase 1 - Getting all act series and principal act ids '.bold
    logger.start 'phase1'
    await getAllActSeriesWithTheirComLawIds
      actSeriesStartingWithLetter: null
      noOfActSeriesToProcess: null
      # Do not use already downloaded data.
      force: false
    , defer e, actSeriesCollection
    saveActSeriesToFile actSeriesCollection
    t = logger.stop 'phase1'
    logger.info "Phase 1 completed (#{t} ms)"
    done e, actSeriesCollection

  # For each act series we download all the files for each act in the
  # series.
  #
  # Their is a manifest file for each act series. We save the location
  # of this file in our **act series manifest** file.

  @phase2: (done) ->
    logger.info 'Phase 2 - Downloading files for each act series'.bold
    actSeriesCollection = loadActSeries()
    for actSeries in actSeriesCollection
      if actSeries.comLawId?
        await ComLaw.downloadActSeries actSeries.comLawId, workDir,
          first: null
          force: false
          filesAlreadyDownloaded: false
        , defer e, acts, manifestDest, baseDir
        return done e if e
        actSeries.manifestFile = manifestDest
        actSeries.baseDir = baseDir
      logger.info "✓ #{actSeries.title}".green
      saveActSeriesToFile actSeriesCollection
    done e, actSeriesCollection

  # For each act series we now convert the HTML to Markdown.

  @phase3: (done) ->
    logger.info 'Phase 3 - Converting HTML to Markdown'.bold
    actSeriesCollection = loadActSeries()
    for actSeries in actSeriesCollection
      continue unless actSeries.comLawId? and actSeries.manifestFile?
      logger.start actSeries.manifestFile
      await ComLaw.convertActsToMarkdown actSeries.manifestFile
      , actSeries.baseDir, defer e
      return done e if e
      duration = logger.stop(actSeries.manifestFile)
      logger.info "✓ #{actSeries.title} (#{duration}ms)".green
    done e, actSeriesCollection

  # For each act series we now add it to the master repo.

  @phase4: (done) ->
    logger.info 'Phase 4 - Creating repo and adding each act series'.bold
    repoPath = path.join workDir, 'masterRepo'
    logger.start 'generate'

    # Delete repo.
    wrench.rmdirSyncRecursive repoPath, true

    await Git.makeGitRepo repoPath, defer e, repo
    return done e if e

    actSeriesCollection = loadActSeries()
    for actSeries in actSeriesCollection

      acts = readManifest actSeries.manifestFile
      continue unless acts? and acts.length

      # Organize acts by:
      #   <lowercased-first-letter-of-act-name>/<cleaned-act-name>
      principalActName = Git.getPrincipalActName acts
      folderName = principalActName.charAt(0).toLowerCase()
      subdir = path.join folderName, principalActName

      await Git.addActsToGitRepo repo, acts,
        subdir: subdir
      , defer e
      return done e if e
      logger.info "✓ #{actSeries.title}".green

    duration = logger.stop 'generate'
    logger.info "✓✓✓ Finished creating repo (#{duration}ms)".green

    done()

  # All
  # ----

  @all: (workDir, done) ->

    await FederalLawScraper.phase1 defer e, actSeriesCollection
    return done e if e

    await FederalLawScraper.phase2 defer e, actSeriesCollection
    return done e if e

    await FederalLawScraper.phase3 defer e, actSeriesCollection
    return done e if e

    await FederalLawScraper.phase4 defer e, actSeriesCollection
    return done e if e

    # We are now done!
    done()

# Save a file containing all consolidated acts with ComLawIds.
getAllActSeriesWithTheirComLawIds = (opts, done) ->
  _.defaults opts,
    actSeriesStartingWithLetter: null
    noOfActSeriesToProcess: null
    force: false

  # 1. Get list of all principal acts of parliament.
  await AustLII.saveConsolidatedActs actSeriesManifestPath,
    letter: opts.actSeriesStartingWithLetter
    force: opts.force
  , defer e, actSeriesCollection
  return done e if e

  # 2. Download bill series for each act of parliament.
  if opts.noOfActSeriesToProcess?
    actSeriesCollection = _.first actSeriesCollection, opts.noOfActSeriesToProcess

  for actSeries, i in actSeriesCollection
    # Skip if we already have the id for this act series.
    unless actSeries.comLawId?
      # Find bill series web page by act name.
      await ComLaw.getComLawIdFromActTitle actSeries.title, defer e, id
      return done e if e
      unless id?
        actSeries.comLawId = null
        logger.info "✗ #{actSeries.title}".red
      else
        actSeries.comLawId = id
        logger.info "✓ #{actSeries.title}".green
        # Process chunks of 10 at a time, then save to file.
        if i % 10 then saveActSeriesToFile actSeriesCollection

  done null, actSeriesCollection
