# A scraper for http://www.comlaw.gov.au/

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

# Libs.
{ActSeries} = require './actSeries'
{ActSeriesPage} = require './actSeriesPage'
{BillDownloadPage} = require './billDownloadPage'

# Constants.
comlawRoot = 'http://www.comlaw.gov.au'

class @ComLaw

  @actSeries: (id, opts, done) ->
    done = opts unless done?
    seriesUrl = "#{comlawRoot}/Series/#{id}"
    actSeries = new ActSeries url: seriesUrl
    actSeries.scrape (e) ->
      return done e if e
      done null, actSeries.getData()

  @downloadActFiles: (id, opts, done) ->
    done = opts unless done?
    #detailsUrl = "#{comlawRoot}/Details/#{act.ComlawId}"
    downloadUrl = "#{comlawRoot}/Details/#{id}/Download"
    downloadRootDest = 'downloads/comlaw/'
    page = new BillDownloadPage
      url: downloadUrl
      billId: id
      downloadRootDest: downloadRootDest
    page.scrape (e) ->
      # Skip files which failed to download.
      return done() unless page.getData().destRelPath?
      src = path.resolve page.getData().destRelPath
      dest = path.resolve path.join downloadRootDest, 'markdown', id  + '.md'
      FileConverter.convertFileToMarkdown src, dest, (e) ->
        return done e if e
        logger.debug 'Converted', src, 'to', dest
        done null, dest

  @downloadAllBillsFromIDOnwards: ->
    "http://www.comlaw.gov.au/Browse/Results/ByID/Bills/Asmade/C2013B000/0"
    # TODO

class FileConverter

  @convertFileToMarkdown: (src, dest, done) =>
    mkdirp.sync path.dirname dest
    cmd = "textutil -convert html #{src} -stdout" +
          " | pandoc -f html -t markdown -o #{dest}"
    child = exec cmd, (e, stdout, stderr) ->
      return done e if e
      #logger.debug stdout, stderr
      done()

  @convertFileToText: (src, dest, done) =>
    mkdirp.sync path.dirname dest
    cmd = "docsplit text #{src} -o #{dest}"
    child = exec cmd, (e, stdout, stderr) ->
      return done e if e
      #logger.debug stdout, stderr
      done()

