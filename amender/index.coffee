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
  amend: (@act, @amendmentActHtml, @opts, done) =>
    unless done? then done = @opts; @opts = {};
    _.defaults @opts,
      onlyProcessFirstN: null
      onlyProcessNth: null
      onlyProcessRange: null

    # Pre-process amendment act html.
    @amendmentActHtml = @amendmentActHtml.replace /&#210;/g, '"'

    # TODO: Don't do this. Do something else.
    @act.originalHtml = @act.originalHtml.replace  /&#8209;/g, '‑'
    @act.originalHtml = @act.originalHtml.replace  /‑/g, '‑'
    @act.originalHtml = @act.originalHtml.replace  /[ ]/g, ' '
    @amendmentActHtml = @amendmentActHtml.replace  /&#8209;/g, '‑'
    @amendmentActHtml = @amendmentActHtml.replace  /‑/g, '‑'
    #@amendmentActHtml = @amendmentActHtml.replace /&nbsp;/g, '\u2002'
    # ---

    @$ = cheerio.load @amendmentActHtml
    $ = @$

    @outputHtml = @act.originalHtml

    # Bill meta-data.
    @data.isAssented = $('.AssentDt').length
    unless @data.isAssented
      @data.house = @$('House').text()

    items = @getAllItems()
    modifiedOriginalHtml = @processAmendments items
    @toMarkdown modifiedOriginalHtml, (e, md, intermediateHtml) ->
      return done e if e
      done null, md, modifiedOriginalHtml, intermediateHtml

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
    amendments = if @opts.onlyProcessNth
      [amendments[@opts.onlyProcessNth - 1]]
    else if @opts.onlyProcessFirstN
      _.first amendments, @opts.onlyProcessNth
    else if @opts.onlyProcessRange
      amendments.slice @opts.onlyProcessRange[0] - 1, @opts.onlyProcessRange[1]
    else amendments

    _.each amendments, (els) => @processAmendment els

    # Return html.
    @outputHtml

  # Process each item.
  processAmendment: (els) =>
    $ = @$
    # First, parse unit and action.
    parser = new AmendmentParser grammar

    prepareBody = ->
      body = ''
      if els.length > 2
        for i in [2..els.length - 1]
          body += $.html (els)[i]
          body += '\n\n'
      body

    amendment = new Amendment parser.parse
      line1: $(els[0]).text()
      line2: $(els[1]).html()
      line3: prepareBody()
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
      url: "http://www.comlaw.gov.au/Details/C2012C00837/Html"
    converter.getHtml (e) ->
      return cb e if e
      converter.convert cb
