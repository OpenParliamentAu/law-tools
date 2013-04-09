logger = require('onelog').get()
request = require 'request'
querystring = require 'querystring'
path = require 'path'
mkdirp = require 'mkdirp'
fs = require 'fs'

{BasePage} = require './basePage'

class @BillDownloadPage extends BasePage

  scraper: (done) =>
    @downloadBillAsWordDocument (e, destRelPath) =>
      return done e if e
      done null, destRelPath

  downloadBillAsWordDocument: (done) =>
    $ = @$
    #id = '#ctl00_MainContent_AttachmentsRepeater_ctl00_ArtifactVersionRenderer_Repeater1_ctl00_ArtifactFormatTableRenderer1_RadGridNonHtml_ctl00_ctl04_hlPrimaryDoc'
    el = $("[id*='hlPrimaryDoc']")
    href = el.attr 'href'
    destRelPathWithoutExt = path.join @opts.downloadRootDest, 'docx', @opts.billId
    unless href?
      # No file download, there might be html/text though.
      el = $ "a[name='Text'] ~ div"
      if $(el).length
        destRelPath = destRelPathWithoutExt + '.html'
        # TODO: Maybe its better to extract text().
        fs.writeFileSync destRelPath, $(el).html()
        return done null, destRelPath
      else
        logger.warn "Skipping act #{@opts.billId}. No Word document found."
        return done null, null
    destRelPath = destRelPathWithoutExt + '.docx'
    logger.debug "Downloading act #{@opts.billId} to #{destRelPath} from #{href}"
    @downloadFile destRelPath, href, (e) =>
      return done e if e
      done null, destRelPath

  downloadFile: (dest, url, done) =>
    mkdirp.sync path.dirname dest
    request(url).pipe(fs.createWriteStream dest)
      .on 'error', (e) ->
        done e
      .on 'close', ->
        done()
      .on 'end', ->
        done()


