logger = require('onelog').get()
request = require 'request'
querystring = require 'querystring'
path = require 'path'
mkdirp = require 'mkdirp'
fs = require 'fs'

{BasePage} = require 'shared'

# A page showing details about a single act.
#
# This page may contain HTML or RTF, but does not have direct links to download
# DOC files.
class @ActPage extends BasePage

  scraper: (done) =>
    @downloadBillHTMLOrRTF (e, data) =>
      return done e if e
      done null, data

  saveFile: (data, ext) =>
    dest = path.join @opts.downloadRootDest, @opts.billId + ext
    mkdirp.sync path.dirname dest
    fs.writeFileSync dest, data
    return dest

  # done(e, text) - does not write to files, returns text.
  downloadBillHTMLOrRTF: (done) =>
    $ = @$

    console.log 'Does Cheerio context exist?', $?

    # Check for inline act HTML.
    sel = '#RAD_SPLITTER_PANE_CONTENT_ctl00_MainContent_ctl05_RadPane2 > div > div'
    htmlEl = $(sel)
    console.log 'Does inline act html exist?', $(htmlEl).length
    if $(htmlEl).length
      html = $(htmlEl).html()
      savedTo = @saveFile html, '.html'
      logger.debug 'Found html'
      return done null,
        files:
          html: savedTo
        data:
          html: html
    else
      # If there is no html, check for rtf download link.
      # TODO: There might only be a PDF.
      rtfDownloadLink = $("[id*='hlPrimaryDoc']")
      if $(rtfDownloadLink).length
        href = rtfDownloadLink.attr 'href'
        @downloadFileInMemory href, (e, data) =>
          return done e if e
          savedTo = @saveFile data, '.rtf'
          logger.debug 'Found rtf'
          return done null,
            files:
              rtf: savedTo
            data:
              rtf: data
      else

        # If no HTML or RTF then skip.
        logger.warn "Skipping act #{@opts.billId}. No HTML or RTF found."
        logger.warn @lastResponse
        return done null, null

  downloadFileInMemory: (url, done) =>
    request
      proxy: @opts.proxy
      url: url
      jar: false
    , (e, r, b) ->
      return done e, b

  # Copied from billDownloadPage.
  #downloadFile: (dest, url, done) =>
  #  mkdirp.sync path.dirname dest
  #  request(url).pipe(fs.createWriteStream dest)
  #    .on 'error', (e) ->
  #      done e
  #    .on 'close', ->
  #      done()
  #    .on 'end', ->
  #      done()
