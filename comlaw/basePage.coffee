logger = require('onelog').get 'BasePage'
request = require 'request'
cheerio = require 'cheerio'
querystring = require 'querystring'
url = require 'url'
extend = require 'xtend'
_ = require 'underscore'

class @BasePage

  constructor: (@opts) ->
    _.defaults @opts,
      url: ''
    @data = {}
    @hasScraped = false
    # This should be set to jquery/cheerio object for document.
    @$ = {}
    # This is the html body of the page.
    @body = {}
    @gotBody = false

  # virtual - Override this.
  scraper: (done) =>

  scrape: (done) =>
    @getHtml (e) =>
      return done e if e
      @scraper (e, data) =>
        return done e if e
        @setData data if data?
        @finishedScraping()
        done null, data

  # Note: `body` will still be set if cheerio fails.
  # We always use html if it is provided.
  # It is suggested that you provide url too for url resolution of relative paths.
  getHtml: (cb) =>
    if @opts.html
      try @$ = cheerio.load(@opts.html) catch e then return cb e
      @body = @opts.html
      @gotBody = true
      return cb null, @opts.html
    cb new Error 'Must set url or html' unless @opts.url
    logger.debug "Scraping #{@opts.url}"
    request @opts.url, (e, r, b) =>
      return cb e if e
      @body = b
      @gotBody = true
      try @$ = cheerio.load(b) catch e then return cb e
      cb null, b

  getData: =>
    unless @hasScraped
      throw new Error 'The #scrape must have completed before you attempt to read data.'
    @data

  getBody: =>
    unless @gotBody
      throw new Error 'You must call #getHtml first.'
    @body

  get$: =>
    unless @gotBody
      throw new Error 'You must call #getHtml first.'
    @$

  setData: (@data) =>

  mergeData: (data) =>
    @data = extend @data, data

  finishedScraping: =>
    @hasScraped = true

  # Extracts rows of data from an html table.
  # Values are labelled by table headings.
  extractTable: (tableId) =>
    $ = @$
    rows = []
    headings = $("#{tableId} > thead > tr > th").map (i, th) -> $(th).text()
    tableRows = $(tableId).children('tbody').children('tr')
    tableRows.each (i, row) =>
      newRow = {}
      $(row).children('td').each (i, col) =>
        newRow[headings[i]] = $(col).text().trim()
        # If there is an anchor link element in the cell we save its href.
        # TODO: Allow saving of multiple elements.
        links = $(col).find('a')
        if links.length
          link = $(links[0]).attr 'href'
          link = url.resolve @opts.url, link
          newRow[headings[i] + ' Link'] = link
      rows.push newRow
    rows
