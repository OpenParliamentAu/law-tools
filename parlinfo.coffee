request = require 'request'
cheerio = require 'cheerio'
FeedParser = require 'feedparser'
_ = require 'underscore'
querystring = require './querystring'
url = require 'url'
async = require 'async'
fs = require 'fs'
path = require 'path'

parlInfoRoot = 'http://parlinfo.aph.gov.au'
#root = 'http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;'
#qs = 'query=Dataset:allmps%20'

class ParlInfo

  @search: (opts, articleCb, done = ->) ->
    rssUrl = "http://parlinfo.aph.gov.au/parlInfo/feeds/rss.w3p;"
    _.defaults opts,
      adv: 'yes'
      # Options: date-eFirst, customrank
      orderBy: 'customrank'
      page: 0
      query: ''
      resCount: 100
    str = querystring.stringify opts, ';'
    compiledUrl = rssUrl + str
    console.log 'Visiting:', str
    request(compiledUrl).pipe(new FeedParser)
      .on 'error', (e) ->
        throw new Error e
      .on 'meta', (meta) ->
        console.log 'meta', meta
      .on 'article', (article) ->
        articleCb article
      .on 'end', ->
        console.log 'Finished'
        done()

  #@findDataset: (dataset, opts) ->

billsCurrentlyBeforeParliament = 'Dataset:billsCurBef'

#ParlInfo.search
#  query: billsCurrentlyBeforeParliament
#, (article) ->
#  console.log 'Scraping:', article.title
#  page = new BillPage url: article.link.toString()
#  page.scrape ->
#    console.log page

class BillPage

  content: {}

  constructor: (@opts) ->

  getHtml: (cb) =>
    return cb @opts.html if @opts.html
    throw new Error 'Must set url or html' unless @opts.url
    request @opts.url, (e, r, b) ->
      throw new Error if e
      cb b

  # Replace slashes with dashes for using as filename.
  @formatSystemId: (id) ->
    id.replace /\//g, '-'

  scrape: (done) =>
    @getHtml (b) =>
      $ = cheerio.load b
      _.extend @content, @scrapeMetadata $
      @content.files = {}
      _.extend @content.files, @scrapeDownloadLinks $
      # Download bill's files to `./downloads` directory.
      formattedSystemId = BillPage.formatSystemId @content['System Id'] + '.docx'
      dest = path.join './downloads/docx/', formattedSystemId
      @content.files.downloadedWordFile = dest
      downloadLink = parlInfoRoot + @content.files['Download Word']
      @downloadFile dest, downloadLink, =>
        @convertFileToText dest, done

  scrapeMetadata: ($) =>
    pairs = $('.metadata .metaPadding > div')
    obj = {}
    pairs.each (i, el) ->
      key = $(el).find('dt.mdLabel').text()
      val = $(el).find('p.mdItem').text().trim()
      obj[key] = val
    obj

  scrapeDownloadLinks: ($) =>
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

page = new BillPage html: fs.readFileSync './fixtures/bill-amendment.html'
page.scrape ->
  console.log page.content
