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

    # Bill meta-data.
    @data.isAssented = $('.AssentDt').length
    unless @data.isAssented
      @data.house = @$('House').text()

    items = @getAllItems()
    html = @processAmendments items
    done null, @toMarkdown html

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
    $ = @$

    # DEBUG
    return @processAmendment amendments[0]

    # Process amendments.
    _.each amendments, (els) =>
      @processAmendment els

  # Process each item.
  processAmendment: (els) =>
    $ = @$

    # First, parse unit and action.
    parser = new AmendmentParser grammar
    amendment = parser.parse
      line1: $(els[0]).text()
      line2: $(els[1]).text()
      line3: $(els[2]).text()

    # TODO: Next, locate the target unit.
    logger.debug 'Locating unit:', amendment.unit

    unit = amendment.unit
    logger.debug "Finding Section #{unit.unitNo} #{unit.subUnitNos} #{unit.unitDescriptor}"

    # TODO: Finally, apply the change.
    @applyAction amendment

  applyAction: (amendment) =>
    logger.debug 'Applying action:', amendment.action
    $ = cheerio.load @act.originalHtml
    unitType = amendment.unit.unitType.toLowerCase()

    map =
      ActHead5: 'section'

    # All unit referencing starts at section.
    sectionNo = amendment.unit.unitNo
    sections = $('.ActHead5')
    section = sections.filter ->
      _sectionNo = $(@).find('.CharSectno').text()
      _sectionNo is sectionNo
    console.log section.text()

    # Get everything in the current section.
    # That is all elements up until another section or end of siblings.
    curr = section
    els = []
    while curr?
      curr = curr.next()
      els.push curr
      if curr.hasClass 'ActHead5'
        curr = null
    console.log els.length

    # Now that we have this section's elements.
    # Find subUnitNo.

    subUnits = amendment.unit.subUnitNos
    curr = subUnits[0]
    i = 0
    while curr?
      i++
      # TODO
      # Find

    for el in els
      console.log el.text()

    # TODO
    return $.html()

  toMarkdown: (html) =>
    $ = cheerio.load html
    md = ''
    $.root().children().each ->
      md += toMarkdown $(@).html()
      md += '\n'
    md
