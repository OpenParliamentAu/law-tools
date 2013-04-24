# Logging.
onelog = require 'onelog'
log4js = require 'log4js'
onelog.use onelog.Log4js
logger = onelog.get()

# Vendor.
_ = require 'underscore'
async = require 'async'
path = require 'path'
fs = require 'fs'
mkdirp = require 'mkdirp'
cheerio = require 'cheerio'

# Libs.
# TODO: Remove relative dependency.
{BasePage} = require '../comlaw/basePage'

root = exports

class @ConsolidatedActsPage extends BasePage

  scraper: (done) =>
    acts = @extractActs()
    done null, acts

  extractActs: =>
    $ = @$ = cheerio.load @body, lowerCaseTags: true
    acts = []
    logger.debug "Bills found:", $('li').length
    _.each $('ul > li'), (li) ->
      link = $(li).find('A').attr 'HREF'
      acts.push
        title: $(li).text()?.replace /\r?\n|\r/gm, ''
        link: link
    acts

class @AustLII

  @getConsolidatedActs = (first, done) ->
    unless done? then done = first; first = null
    letters = (String.fromCharCode(x + 65) for x in [0..25])
    letters = _.first letters, first if first?
    acts = []
    async.eachSeries letters, (letter, done) ->
      url = "http://www.austlii.edu.au/au/legis/cth/consol_act/toc-#{letter}.html"
      page = new root.ConsolidatedActsPage {url}
      page.scrape (e) ->
        return done e if e
        acts = acts.concat page.getData()
        done()
    , (e) ->
      return done e if e
      done null, acts

  @saveConsolidatedActs = (dest, opts, done) ->
    unless done? then done = opts; opts = {}
    _.defaults opts, first: null
    AustLII.getConsolidatedActs opts.first, (e, acts) ->
      return done e if e
      mkdirp.sync path.dirname dest
      fs.writeFileSync dest, JSON.stringify(acts, null, 2)
      logger.info 'Downloaded consolidated act names to', dest
      done null, acts
