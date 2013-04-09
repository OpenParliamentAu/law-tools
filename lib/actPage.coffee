logger = require('onelog').get()
request = require 'request'
querystring = require 'querystring'
path = require 'path'
mkdirp = require 'mkdirp'
fs = require 'fs'

{BasePage} = require './basePage'

class @ActPage extends BasePage

  scraper: (done) =>
    @downloadBillHTMLOrRTF (e, html) =>
      return done e if e
      done null, html

  # done(e, text) - does not write to files, returns text.
  downloadBillHTMLOrRTF: (done) =>
    $ = @$

    # Check for inline act HTML.
    id = '#RAD_SPLITTER_PANE_CONTENT_ctl00_MainContent_ctl05_RadPane2'
    htmlEl = $(id)
    if $(htmlEl).length
      html = $(htmlEl).html()
      dest = path.join @opts.downloadRootDest, 'html', @opts.billId + '.html'
      mkdirp.sync path.dirname dest
      fs.writeFileSync dest, html
      return done null, {html}

    # If there is no html, check for rtf download link.
    # TODO: There might only be a PDF.
    rtfDownloadLink = $("[id*='hlPrimaryDoc']")
    if $(rtfDownloadLink).length
      href = rtfDownloadLink.attr 'href'
      dest = path.join @opts.downloadRootDest, 'rtf', @opts.billId + '.rtf'
      @downloadFileInMemory dest, href, (e, file) =>
        return done e if e
        done null, rtf: file
      return

    # If no HTML or RTF then skip.
    logger.warn "Skipping act #{@opts.billId}. No HTML or RTF found."
    return done null, null

  downloadFileInMemory: (dest, url, done) =>
    mkdirp.sync path.dirname dest
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
