# Experiments for headless browser scraping because ComLaw uses ajax grids
# which use ASP.NET POST endpoints which require a server-side generated
# string to be sent as a hidden field (__VIEWSTATE).

request = require 'request'
cheerio = require 'cheerio'
_ = require 'underscore'
querystring = require 'querystring'
url = require 'url'
async = require 'async'
fs = require 'fs'
path = require 'path'
mkdirp = require 'mkdirp'

comlawRoot = 'http://www.comlaw.gov.au/'

marriageAct = 'C1961A00012'

getAllPagesForActSeriesWithZombie = ->
  seriesUrl = "#{comlawRoot}Series/#{marriageAct}"
  zombie = require 'zombie'
  browser = new zombie
  #browser.runScripts = false
  browser.on 'error', (e) ->
    console.error e
  browser.visit seriesUrl,
    debug: true
  .then ->
    console.log browser
    browser.clickLink '2'
  .then ->
    console.log 'clicked', browser

getAllPagesForActSeriesWithCasper = ->
  seriesUrl = "#{comlawRoot}Series/#{marriageAct}"
  links = []
  getLinks = ->
    links = document.querySelectorAll "h3.r a"
    Array::map.call links, (e) -> e.getAttribute "href"
  casper.start seriesUrl, ->
  casper.then ->
    @evaluate getLinks
  casper.run ->
    @echo links.length, 'links found'

getAllPagesForActSeriesWithPhantom = ->
  seriesUrl = "#{comlawRoot}/Series/#{marriageAct}"
  phantom = require 'phantom'
  phantom.create (ph) ->
    ph.createPage (page) ->
      page.open seriesUrl, (status) ->
        console.log "opened site? ", status
        page.includeJs 'http://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js', ->
          setTimeout ->
            page.evaluate ->
              html: $('.rgPageNext')[0]
              title: document.title
            , (result) ->
              console.log 'Page title is ', result
              ph.exit()
          , 5000

getAllPagesForActSeriesWithSpooky = ->
  seriesUrl = "#{comlawRoot}Series/#{marriageAct}"
  Spooky = require 'spooky'
  spooky = new Spooky
    casper:
      logLevel: 'debug'
      verbose: true
  , (e) ->
    throw e if e
    spooky.on 'error', (e) ->
      console.error 'Error:', e
    spooky.on 'log', (log) ->
      #if log.space is 'remote'
      #  console.log log.message
      console.log log

    spooky.start seriesUrl
    spooky.thenEvaluate ->
      console.log('Hello, from', document.title);
    spooky.then ->
      #@click '.rgPageNext'
      @echo 'hellllllo'
    spooky.run()

#getAllPagesForActSeriesWithSpooky()
#getAllPagesForActSeriesWithPhantom()
#getAllPagesForActSeriesWithZombie()
