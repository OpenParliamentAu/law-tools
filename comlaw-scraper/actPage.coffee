logger = require('onelog').get()
request = require 'request'
querystring = require 'querystring'
path = require 'path'
mkdirp = require 'mkdirp'
fs = require 'fs'

{BasePage} = require './basePage'

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

  # done(e, text) - does not write to files, returns text.
  downloadBillHTMLOrRTF: (done) =>
    $ = @$

    # Check for inline act HTML.
    sel = '#RAD_SPLITTER_PANE_CONTENT_ctl00_MainContent_ctl05_RadPane2 > div > div'
    htmlEl = $(sel)
    if $(htmlEl).length
      html = $(htmlEl).html()
      @saveFile html, '.html'
      logger.debug 'Found html'
      return done null, {html}
    else
      # If there is no html, check for rtf download link.
      # TODO: There might only be a PDF.
      rtfDownloadLink = $("[id*='hlPrimaryDoc']")
      if $(rtfDownloadLink).length
        href = rtfDownloadLink.attr 'href'
        @downloadFileInMemory href, (e, data) =>
          return done e if e
          @saveFile data, '.rtf'
          logger.debug 'Found rtf'
          done null, rtf: data
      else

        # If no HTML or RTF then skip.
        logger.warn "Skipping act #{@opts.billId}. No HTML or RTF found."
        return done null, null

  downloadFileInMemory: (url, done) =>
    request url, (e, r, b) ->
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
