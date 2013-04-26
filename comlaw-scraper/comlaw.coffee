#
# A scraper for http://www.comlaw.gov.au/
#

# Logging.
onelog = require 'onelog'
log4js = require 'log4js'
onelog.use onelog.Log4js
logger = onelog.get()

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

# Constants.
comlawRoot = 'http://www.comlaw.gov.au'

class @ComLaw

  # Download act meta-data for each act in a series for given ComLawId.
  @actSeries: (id, opts, done) ->
    unless done? then done = opts; opts = {}
    seriesUrl = "#{comlawRoot}/Series/#{id}"
    actSeries = new ActSeries url: seriesUrl
    actSeries.scrape (e, data) ->
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
    page.scrape done

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
      data = data.acts[0]['Title Link']
      data = data.replace 'http://www.comlaw.gov.au/Details/', ''
      done null, data

  @downloadActSeriesAndConvertToMarkdown: (comLawId, workDir, opts, done) ->
    unless done? then done = opts; opts = {}
    downloadedFilesDir = path.join workDir, 'files'
    markdownDir = path.join workDir, 'md'

    ComLaw.actSeries comLawId, (e, acts) ->
      throw e if e
      unless acts?.length then return logger.debug 'No acts found'
      if opts.first then acts = _.first acts, opts.first
      async.eachSeries acts, (actData, cb) ->
        ComLaw.downloadAct actData.ComlawId,
          downloadDir: downloadedFilesDir
        , (e, act) ->
          return cb e if e
          markdownDest = path.join markdownDir, actData.ComlawId + '.md'
          ComLaw.convertToMarkdown actData.ComlawId, act, markdownDest, (e) ->
            return cb e if e
            # Attach the generated Markdown file to the act.
            actData.masterFile = markdownDest
            cb()
      , (e) ->
        return done e if e
        logger.info 'Successfully finished downloading act series and files'
        logger.info acts
        done null, acts

