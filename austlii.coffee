# Logging.
onelog = require 'onelog'
log4js = require 'log4js'
onelog.use onelog.Log4js
logger = onelog.get()

_ = require 'underscore'
async = require 'async'

{BasePage} = require './lib/basePage'

class ConsolidatedActsPage extends BasePage

  scraper: (done) =>
    acts = @extractActs()
    done null, acts

  extractActs: =>
    $ = @$ = require('cheerio').load @body, lowerCaseTags: true
    acts = []
    logger.debug "Bills found:", $('li').length
    _.each $('ul > li'), (li) ->
      link = $(li).find('A').attr 'HREF'
      acts.push
        title: $(li).text()?.replace /\r?\n|\r/gm, ''
        link: link
    acts

countConsolidatedActs = ->

  letters = (String.fromCharCode(x + 65) for x in [0..25])
  acts = []
  async.each letters, (letter, done) ->
    url = "http://www.austlii.edu.au/au/legis/cth/consol_act/toc-#{letter}.html"
    page = new ConsolidatedActsPage {url}
    page.scrape (e) ->
      return done e if e
      acts = acts.concat page.getData()
      done()
  , (e) ->
    throw e if e
    console.log acts
    console.log acts.length

countConsolidatedActs()
