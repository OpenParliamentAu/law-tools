request = require 'request'
cheerio = require 'cheerio'
FeedParser = require 'feedparser'
_ = require 'underscore'
querystring = require 'querystring'
url = require 'url'
async = require 'async'
fs = require 'fs'
path = require 'path'

{BasePage} = require '../lib/basePage'

class @BillPage extends BasePage

  # Replace slashes with dashes for using as filename.
  @formatSystemId: (id) ->
    id.replace /\//g, '-'

  scraper: (done) =>
    $ = @$
    @mergeData meta: @scrapeMetadata()
    @margeData files: @scrapeDownloadLinks()

    formattedSystemId = BillPage.formatSystemId @data['System Id'] + '.docx'
    dest = path.join './downloads/docx/', formattedSystemId
    @data.files.downloadedWordFile = dest
    downloadLink = parlInfoRoot + @data.files['Download Word']
    @downloadFile dest, downloadLink, =>
      @convertFileToText dest, done

  scrapeMetadata: =>
    $ = @$
    pairs = $('.metadata .metaPadding > div')
    obj = {}
    pairs.each (i, el) ->
      key = $(el).find('dt.mdLabel').text()
      val = $(el).find('p.mdItem').text().trim()
      obj[key] = val
    obj

  scrapeDownloadLinks: =>
    $ = @$
    obj = {}
    $('#content > .box a').each (i, el) ->
      key = $(el).text()
      val = $(el).attr 'href'
      obj[key] = val
    obj

  downloadFile: (dest, url, done) =>
    request(url).pipe(fs.createWriteStream dest)
      .on 'error', (e) ->
        throw new Error e
      .on 'close', ->
        console.log 'Close event fired'
        done()
      .on 'end', ->
        console.log 'Finished'
        done()

  convertFileToText: (file, done) =>
    {exec} = require 'child_process'
    fullPath = path.join process.cwd(), file
    child = exec "docsplit text #{fullPath} -o downloads/text", (e, stdout, stderr) ->
      throw new Error e if e
      console.log stdout, stderr
      done()
