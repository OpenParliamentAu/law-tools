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
fs = require 'fs'

# Libs.
{ActSeries} = require './actSeries'
{ActSeriesPage} = require './actSeriesPage'
{BillDownloadPage} = require './billDownloadPage'
{ActPage} = require './actPage'

# Constants.
comlawRoot = 'http://www.comlaw.gov.au'

class @ComLaw

  @actSeries: (id, opts, done) ->
    done = opts unless done?
    seriesUrl = "#{comlawRoot}/Series/#{id}"
    actSeries = new ActSeries url: seriesUrl
    actSeries.scrape (e, data) ->
      return done e if e
      done null, data

  @downloadActFiles: (id, opts, done) ->
    done = opts unless done?
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
      FileConverter.convertFileToMarkdown src, dest, (e) ->
        return done e if e
        logger.debug 'Converted', src, 'to', dest
        done null, dest

  @downloadActHTML: (id, opts, done) ->
    done = opts unless done?
    detailsUrl = "#{comlawRoot}/Details/#{id}"
    downloadRootDest = 'downloads/comlaw/'
    page = new ActPage
      url: detailsUrl
      billId: id
      downloadRootDest: downloadRootDest
    page.scrape (e, data) ->
      return done e if e
      return done() unless data?
      dest = path.resolve path.join downloadRootDest, 'markdown', id  + '.md'

      # HTML.
      if data.html?
        CustomFileConverter.convertHTMLtoMarkdown data.html, dest, (e) ->
          return done e if e
          logger.debug "Converted HTML bill #{id} to", dest
          done null, dest

      else if data.rtf?
        CustomFileConverter.convertRTFtoMarkdown data.rtf, dest, (e) ->
           return done e if e
           logger.debug "Converted rtf bill #{id} to", dest
           done null, dest

      else
        done null, null

  @downloadAllBillsFromIDOnwards: ->
    "http://www.comlaw.gov.au/Browse/Results/ByID/Bills/Asmade/C2013B000/0"
    # TODO

# This is a converter I have written to manually convert Word HTML.
class CustomFileConverter

  @convertHTMLtoMarkdown: (html, dest, done) =>
    {toMarkdown} = require './to-markdown'
    out = toMarkdown html
    fs.writeFileSync dest, out
    done()

  @convertRTFtoMarkdown: (html, dest, done) =>
    logger.error 'TODO'
    done()

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

