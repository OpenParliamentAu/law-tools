# Logging.
onelog = require 'onelog'
log4js = require 'log4js'
onelog.use onelog.Log4js, methods: 'setLevel'
logger = onelog.get()
log4js.setGlobalLogLevel 'DEBUG'

request = require 'request'
cheerio = require 'cheerio'
_ = require 'underscore'
querystring = require 'querystring'
url = require 'url'
async = require 'async'
fs = require 'fs'
path = require 'path'
mkdirp = require 'mkdirp'

comlawRoot = 'http://www.comlaw.gov.au'

{ActSeriesPage} = require './actSeriesPage'

class @ActSeries

  getData: => @data

  constructor: (@opts) ->
    @seriesUrl = @opts.url
    # We store all the acts here.
    @data = []
    # Used as the condition in our while loop.
    @_noMorePages = false

  noMorePages: ($, el) =>
    @_noMorePages = $(el).attr('onclick')?

  scrapeFirstPage: (done) =>
    page = new ActSeriesPage url: @seriesUrl
    page.scrape (e, data) =>
      return done e if e
      $ = page.get$()
      nextPageEl = $('.rgPageNext')[0]
      @noMorePages $, nextPageEl
      @data = @data.concat data.acts
      done null, page.getBody()

  # Emulate clicking next page link until next page link has attribute:
  #     onclick="return false;"
  # which means there are no more pages.
  # We emulate a form submit event to acheive this.
  # Trust me, this is the only way!
  #
  # body - html from the last visited page
  scrapeNextPage: (body, done) =>
    logger.debug 'Scraping next page with length:', body.length
    $ = cheerio.load body
    nextPageEl = $('.rgPageNext')[0]
    return done() if @noMorePages $, nextPageEl

    # Prepare form data into object.
    inputs = $('form input')
    obj = {}
    _.each inputs, (input) ->
      type = $(input).attr('type')
      return if type is 'submit'
      key = $(input).attr 'name'
      val = $(input).attr 'value'
      obj[key] = val or ''
    # We include the key of the next input button we use to submit the form
    # which tells the server we want the next page.
    # The current page is probably stored in `__VIEWSTATE`.
    nextPageElName = $(nextPageEl).attr 'name'
    obj[nextPageElName] = ' '
    logger.trace 'Prepared POST form data:', obj

    # Send off a request with all the hidden fields + the button we pressed.
    request.post @seriesUrl,
      form: obj
    , (e, r, b) =>
      return done e if e
      page = new ActSeriesPage html: b
      page.scrape (e, data) =>
        return done e if e
        @data = @data.concat data.acts
        done null, b

  scrape: (done) =>
    first = true
    body = {}
    async.until (=> @_noMorePages), (done) =>
      if first
        @scrapeFirstPage (e, recentPageBody) ->
          return done e if e
          first = false
          body = recentPageBody
          done()
      else
        @scrapeNextPage body, (e, recentPageBody) ->
          return done e if e
          body = recentPageBody
          done()
    , (e) =>
      return done e if e
      logger.debug 'There are no more pages.'
      done null, @data

#marriageAct = 'C1961A00012'
#actSeries = new @ActSeries id: marriageAct
#actSeries.scrape (e, acts) =>
#  return logger.error e if e
#  logger.info acts
