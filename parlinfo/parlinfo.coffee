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

  @search: (opts, done = ->) ->
    articles = []
    metadata = {}
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
        done e
      .on 'meta', (meta) ->
        metadata = meta
      .on 'article', (article) ->
        articles.push article
      .on 'end', ->
        done e, articles


# main
# ----

#Ordered bills
#http://aph.gov.au/Parliamentary_Business/Bills_Legislation/Bills_Search_Results/Result?bId=r4946

beforeParliament = 'Dataset:billsCurBef Dataset_Phrase:"billhome"'
billsCurrentlyBeforeParliament = 'Dataset:billsCurBef'

scrapeBillsCurrentlyBeforeParliament = ->
  ParlInfo.search
    query: billsCurrentlyBeforeParliament
  , (articles) ->
    tasks = _.map articles, (article) ->
      fn = (done) ->
        console.log 'Scraping bill:', article.title
        page = new BillPage url: article.link.toString()
        page.scrape done
      fn
    async.parallel tasks, (e, r) ->
      console.log e, r

page = new BillPage html: fs.readFileSync './fixtures/bill-amendment.html'
page.scrape ->
  console.log page.content

#scrapeBillsCurrentlyBeforeParliament()
