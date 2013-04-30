# Logging.
logger = require('onelog').get()

# Vendor.
async = require 'async'
{exec} = require 'child_process'
mkdirp = require 'mkdirp'
path = require 'path'
fs = require 'fs'
_ = require 'underscore'

# Libs.
{ActSeries} = require './actSeries'
{ActSeriesPage} = require './actSeriesPage'
{SearchResultsPage} = require './searchResultsPage'
{BillDownloadPage} = require './billDownloadPage'
{ActPage} = require './actPage'
{Converter} = require './converter'
pjson = require './package.json'

# Constants.
comlawRoot = 'http://www.comlaw.gov.au'

# Helpers.
writeManifest = (manifestDest, acts) ->
  fs.writeFileSync manifestDest, JSON.stringify(acts, null, 2)

readManifest = (manifestDest) ->
  return null unless manifestDest?
  if fs.existsSync manifestDest
    require manifestDest
  else
    null

#
# A scraper for http://www.comlaw.gov.au/
#
class @ComLaw

  @getVersion: ->
    # Get package version.
    pjson.version

  # Download act meta-data for each act in a series for given ComLawId.
  @actSeries: (id, opts, done) ->
    unless done? then done = opts; opts = {}
    seriesUrl = "#{comlawRoot}/Series/#{id}"
    actSeries = new ActSeries url: seriesUrl
    await actSeries.scrape defer e, data
    return done e if e
    done null, data

  # For a given ComLawId.
  # - Try to scrape HTML.
  # - Try to scrape RTF.
  # Returns (err, actData).
  #   actData has same keys as titles from ComLaw html data table.
  @downloadAct: (id, opts, done) ->
    unless done? then done = opts; opts = {}
    detailsUrl = "#{comlawRoot}/Details/#{id}"
    page = new ActPage
      url: detailsUrl
      billId: id
      downloadRootDest: opts.downloadDir
    page.scrape (e, data) ->
      if e?
        console.error 'downloadActError:', e
      done e, data

  @convertToMarkdown: (id, actData, dest, done) =>
    Converter.convertToMarkdown id, actData, dest, done

  # Download .doc file for act and convert to Markdown.
  # TODO: Uses FileConverter which we do not use.
  @downloadActFiles: (id, opts, done) ->
    unless done? then done = opts; opts = {}
    downloadUrl = "#{comlawRoot}/Details/#{id}/Download"
    downloadRootDest = 'downloads/comlaw/'
    page = new BillDownloadPage
      url: downloadUrl
      billId: id
      downloadRootDest: downloadRootDest
    page.scrape (e, data) ->
      return done e if e
      # Skip files which failed to download.
      return done() unless data.destRelPath?
      src = path.resolve data.destRelPath
      dest = path.resolve path.join downloadRootDest, 'markdown', id  + '.md'
      Converter.FileConverter.convertFileToMarkdown src, dest, (e) ->
        return done e if e
        logger.debug 'Converted', src, 'to', dest
        done null, dest

  @downloadAllBillsFromIDOnwards: ->
    "http://www.comlaw.gov.au/Browse/Results/ByID/Bills/Asmade/C2013B000/0"
    # TODO

  @getComLawIdFromActTitle: (actTitle, done) ->
    q = encodeURIComponent actTitle
    searchUrl = "#{comlawRoot}/Search/#{q}"
    searchResultsPage = new SearchResultsPage url: searchUrl
    searchResultsPage.scrape (e, data) ->
      return done e if e
      #data = data.acts[0]['Title Link']
      #data = data.replace 'http://www.comlaw.gov.au/Details/', ''
      seriesComLawId = data.acts[0]?['seriesComLawId']
      unless seriesComLawId?
        logger.warn 'Could not find seriesComLawId for page:', searchUrl
      done null, seriesComLawId

  @downloadActSeriesAndConvertToMarkdown: (comLawId, workDir, opts, done) ->
    ComLaw.downloadActSeries comLawId, workDir, opts, (e, acts, manifestDest, baseDir) ->
      return done e if e
      ComLaw.convertActsToMarkdown manifestDest, baseDir, done

  @downloadActSeries: (comLawId, workDir, opts, done) ->
    unless done? then done = opts; opts = {}
    _.defaults opts,
      force: false
      first: null
      # If we already have the files and want to rebuild the manifest
      # files enable this.
      # I had to use it when I accidentally overwrote all the manifest
      # files.
      filesAlreadyDownloaded: false

    # Each act series is saved in its own folder.
    baseDir = path.join workDir, comLawId
    mkdirp.sync baseDir
    downloadedFilesDir = path.join baseDir, 'files'
    # Manifest contains meta-data for all acts in the series
    # and the path to any downloaded files for each act.
    manifestDest = path.join baseDir, 'manifest.json'

    # Unless we have already downloaded all the meta-data,
    # download all act meta-data in act series and save to manifest.
    manifest = readManifest manifestDest

    if opts.force
      # Always get act series meta-data.
      await ComLaw.actSeries comLawId, defer e, acts
      return done e if e
    else
      if manifest?
        if manifest instanceof Array
          # Valid manifest file.
          acts = manifest
        else
          # Invalid manifest file. Get.
          await ComLaw.actSeries comLawId, defer e, acts
          return done e if e
      else
        # Manifest file doesn't exist. Get.
        await ComLaw.actSeries comLawId, defer e, acts
        return done e if e

    # I used the following code to rebuild the act series manifest files
    # after I accidentally overwrote them.
    #
    # We search the downloadedFilesDir for rtf and html and add
    # this data to the manifest if we find it.

    if opts.filesAlreadyDownloaded
      for actData in acts
        continue if actData.files?
        destBase = path.join downloadedFilesDir, actData.ComlawId
        if fs.existsSync destBase + '.html'
          actData.files = html: destBase + '.html'
          actData.versionScraper = ComLaw.getVersion()
        else if fs.existsSync destBase + '.rtf'
          actData.files = rtf: destBase + '.rtf'
          actData.versionScraper = ComLaw.getVersion()
      writeManifest manifestDest, acts
      return done null, acts, manifestDest, baseDir

    # ---

    unless acts?.length
      logger.debug 'No acts found'
      return done null, [], manifestDest, baseDir

    if opts.first then acts = _.first acts, opts.first

    # For each act, download its contents in html or rtf.
    # Add properties to `acts` for the path to the files and meta-data.
    for actData in acts
      continue if actData.files? # Skip if we have already processed it.
      await ComLaw.downloadAct actData.ComlawId,
        downloadDir: downloadedFilesDir
      , defer e, data
      if e and e.type is 'CheerioParseError'
        logger.warn 'CheerioParseError'
        continue
      else if e
        return done e
      continue unless data?
      actData.files = data.files
      actData.versionScraper = ComLaw.getVersion()
      await process.nextTick defer()

    # Save act series to a json manifest file.
    writeManifest manifestDest, acts
    logger.debug 'Wrote manfiest.json to:', manifestDest
    logger.debug 'Successfully finished downloading act series and files'
    logger.debug acts

    done null, acts, manifestDest, baseDir

  @convertActsToMarkdown: (manifestDest, baseDir, done) ->
    # Convert all acts in series to Markdown from act manifest.
    acts = readManifest manifestDest
    convertedCount = 0
    for actData in acts
      continue unless actData.files?
      continue if actData.output?
      await ComLaw.convertToMarkdownFromManifest actData, baseDir, defer e
      return done e if e
      ++convertedCount

    # Update manifest with path to Markdown files.
    writeManifest manifestDest, acts
    logger.debug "Finished converting #{convertedCount}/#{acts.length} acts to Markdown"
    done null, acts

  @convertToMarkdownFromManifest: (actData, baseDir, done) ->
    markdownDir = path.join baseDir, 'md'
    mkdirp.sync markdownDir
    markdownDest = path.join markdownDir, actData.ComlawId + '.md'

    # Read source files.
    data = {}
    if actData.files.html?
      data.html = fs.readFileSync actData.files.html, 'utf-8'
    if actData.files.rtf?
      data.rtf = fs.readFileSync actData.files.rtf, 'utf-8'

    # Convert.
    await ComLaw.convertToMarkdown actData.ComlawId, data, markdownDest
    , defer e, dest, compilerInfo
    return done e if e

    # Attach the generated Markdown file to the act.
    actData.output =
      path: markdownDest
      compiler: compilerInfo

    done()
