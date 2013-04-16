# Vendor.
cheerio = require 'cheerio'
_ = require 'underscore'

# Logging.
onelog = require 'onelog'
log4js = require 'log4js'
onelog.use onelog.Log4js
logger = onelog.get 'Amender'
logger.setLevel 'DEBUG'
#logger.setLevel 'TRACE'

# Libs.
{toMarkdown} = require '../comLawToMarkdown/lib/to-markdown/to-markdown'
{Parser} = require './parser'

class @Amender

  constructor: ->
    @data = {}

  getAllItems: =>
    $ = @$
    # Get all amendments. They are separated by ItemHeads.
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

  processAmendments: (amendments) =>
    $ = @$
    # Process amendments.
    _.each amendments, (els) =>
      @processAmendment els

  processAmendment: (els) =>
    $ = @$
    #console.log 'Processing amendment:\n'
    _.each els, (el) ->
      console.log $(el).text()
    #console.log '---'

  amend: (act, amendment, done) =>
    @$ = cheerio.load amendment
    $ = @$

    # Bill meta-data.
    @data.isAssented = $('.AssentDt').length
    unless @data.isAssented
      @data.house = @$('House').text()

    amendments = @getAllItems()
    @processAmendments amendments[0]
    done null, @toMarkdown act

  toMarkdown: (act) =>
    $ = cheerio.load act.html
    md = ''
    $.root().children().each ->
      md += toMarkdown $(@).html()
      md += '\n'
    md
