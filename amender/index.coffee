# Vendor.
cheerio = require 'cheerio'
_ = require 'underscore'
fs = require 'fs'
path = require 'path'

# Logging.
onelog = require 'onelog'
log4js = require 'log4js'
onelog.use onelog.Log4js
logger = onelog.get 'Amender'
logger.setLevel 'DEBUG'
#logger.setLevel 'TRACE'

# Libs.
{toMarkdown} = require '../comLawToMarkdown/lib/to-markdown/to-markdown'
{AmendmentParser} = require './amendmentParser'
{Amendment} = require './amendment'
{Converter} = require '../comLawToMarkdown'

# Constants.
grammar =
  header: fs.readFileSync './grammar/header.pegjs', 'utf-8'
  action: fs.readFileSync './grammar/action.pegjs', 'utf-8'

class @Amender

  constructor: ->
    @data = {}

  # This is the main function.
  amend: (@act, @amendmentActHtml, done) =>
    @$ = cheerio.load @amendmentActHtml
    $ = @$
    @outputHtml = @act.originalHtml

    # Bill meta-data.
    @data.isAssented = $('.AssentDt').length
    unless @data.isAssented
      @data.house = @$('House').text()

    items = @getAllItems()
    html = @processAmendments items
    @toMarkdown html, (e, md) ->
      return done e if e
      done null, md

  # First we get all the amendment items.
  # They are separated by `.ItemHead` elements.
  getAllItems: =>
    $ = @$
    items = []
    $('.ItemHead').each ->
      els = []
      curr = @
      prev = null
      loop
        els.push curr
        prev = curr
        curr = $(curr).next()
        break if $(curr).hasClass('ItemHead') or curr is prev
      items.push els
    items

  # Each item is composed of a few elements on the same level in the dom tree.
  # E.g. When replacing a definition:
  #
  #   .ItemHead - identifies the affected unit
  #   .Item - the action line of what change is to be made
  #   .Definition - the formatted definition
  #
  # Each item is processed separately.
  processAmendments: (amendments) =>

    # Process amendments.
    _.each _.first(amendments, 7), (els) =>
      @processAmendment els

    # Return html.
    @outputHtml

  # Process each item.
  processAmendment: (els) =>
    $ = @$
    # First, parse unit and action.
    parser = new AmendmentParser grammar
    amendment = new Amendment parser.parse
      line1: $(els[0]).text()
      line2: $(els[1]).html()
      line3: $(els[2]).html()
    # Applies the amendment to some html and returns the new html.
    @outputHtml = amendment.apply @outputHtml
    @outputHtml

  toMarkdown: (html, cb) =>
    converter = new Converter html,
      outputSplit: false
      outputDebug: false
      justMd: true
      cleanTables: true
      linkifyDefinitions: false
    converter.getHtml (e) ->
      return cb e if e
      converter.convert cb
