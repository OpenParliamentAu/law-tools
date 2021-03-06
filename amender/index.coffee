# Vendor.
cheerio = require 'cheerio'
_ = require 'underscore'
fs = require 'fs'
path = require 'path'

# Logging.
onelog = require 'onelog'
logger = onelog.get 'Amender'
#logger.setLevel 'OFF'

# Libs.
#{toMarkdown} = require 'to-markdown'
{Converter} = require 'comlaw-to-markdown'
{AmendmentParser} = require './amendmentParser'
{Amendment} = require './amendment'

# Constants.
grammar =
  header: fs.readFileSync path.join(__dirname, 'grammar/header.pegjs'), 'utf-8'
  action: fs.readFileSync path.join(__dirname, 'grammar/action.pegjs'), 'utf-8'


# Amender takes the Word HTML of an Amendment Act, parses it, and applies
# amendments to one or more Consolidated Acts.
class @Amender

  # We pass in the Word HTML of the Amendment Act.
  constructor: (@amendmentActHtml) ->
    # Pre-process amendment act html. This is neccessary because the HTML
    # is encoded as Windows-1252 and we only operate on UTF-8.
    # TODO: This is messy and should be centralized somewhere.
    @amendmentActHtml = @amendmentActHtml.replace /&#210;/g, '"'
    # Clean amendment act html.
    # TODO: Do something different.
    @amendmentActHtml
      .replace(/&#8209;/g, '‑')
      .replace(/‑/g, '‑')
      #.replace /&nbsp;/g, '\u2002'
    # Parse the HTML using Cheerio and make accessible to the rest of the class.
    @$ = cheerio.load @amendmentActHtml

  # Returns an array of all acts which this Amendment Act amends.
  # This is neccessary because the amendee acts are downloaded and converted
  # to HTML externally, and then passed into the `amend` method.
  getAmendedActs: =>
    acts = @getActs()
    _.unique (act.title for act in acts)

  # This is the main function.
  amend: (actsHtml, @opts, done) =>
    unless done? then done = @opts; @opts = {};
    _.defaults @opts,
      onlyProcessFirstN: null
      onlyProcessNth: null
      onlyProcessRange: null

    # For convenience.
    $ = @$

    # Check all required acts have been passed in.
    amendedActs = @getAmendedActs()

    # TODO: Not needed.
    #unless _.all(amendedActs, (act) -> actsHtml[act]?)
    #  return done 'You must pass in an acts hash containing html for all acts.'

    # TODO: Don't do this. Do something else in the future!

    # Clean acts.
    for act of actsHtml
      continue unless act?
      act = act
        .replace(/&#8209;/g, '‑')
        .replace(/‑/g, '‑')
        .replace(/[ ]/g, ' ')
        .replace(/&#146;/g, ' ')

    # Prepare output hash.
    @output = {}
    logger.debug "\n"
    logger.debug "Amending acts:"
    for title in amendedActs
      logger.debug "#{title} (size=#{actsHtml[title]?.length})"
      continue unless actsHtml[title]?
      @output[title] =
        modifiedOriginalHtml: actsHtml[title]
        # Bill meta-data.
        data:
          isAssented: $('.AssentDt').length
      unless @output[title].data.isAssented
        @output[title].data.house = @$('House').text()

    # Each schedule will amend one or more acts.
    schedules = @getSchedules()
    for schedule in schedules
      acts = @getActs schedule.els
      for act in acts
        # Skip if we didn't provide original html for this act.
        continue unless @output[act.title]?
        items = @getAllItems act.children
        @output[act.title].modifiedOriginalHtml =
          @processAmendments schedule.text, act.title, items, @output[act.title].modifiedOriginalHtml
        #console.log act.title, @output[act.title].modifiedOriginalHtml?.length

    # Convert each act to Intermediate HTML and then Markdown.
    for title, act of @output
      await @toMarkdown act.modifiedOriginalHtml, defer e, md, intermediateHtml
      return done e if e
      act.intermediateHtml = intermediateHtml
      act.markdown = md

    # Return hash of act -> intermediate html and Markdown of amended act.
    done null, @output

  getActs: (scheduleEls) =>
    $ = @$
    # Find all the act headers in this schedule.
    if scheduleEls?
      actEls = $(scheduleEls).filter -> @hasClass 'ActHead9'
    else
      actEls = $('.ActHead9')
    actEls.map ->
      el: @
      title: @text().replaceLineBreaks()
      children: $(@).nextUntil ->
        # Find next heading that is higher in header hierarchy.
        matched = /ActHead[0-8]/.test @attr('class')
        matched

  # TODO: Rewrite functionally like above.
  getSchedules: =>
    $ = @$

    schedules = []
    els = $('.ActHead6')
    for el, i in els
      scheduleEls = $(el).getElementsUntilClass 'ActHead6'
      schedules.push
        el: el
        text: $(el).text()
        els: scheduleEls
    schedules

  # First we get all the amendment items in this schedule.
  # They are separated by `.ItemHead` elements.
  getAllItems: (els) =>

    # These classes are used as dividers in the amendment bill.
    # When we find one, we are finished with the current amendment.
    #classes = ['ActHead7']
    classes = []

    $ = @$
    items = []
    itemHeads = $(els).filter -> @hasClass 'ItemHead'
    itemHeads.each ->
      els = []
      curr = @
      prev = null
      loop
        els.push curr
        prev = curr
        curr = $(curr).next()
        end = _.any classes, (clazz) -> $(curr).hasClass(clazz)
        break if $(curr).hasClass('ItemHead') or end or curr is prev or curr.length is 0
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
  processAmendments: (schedule, actTitle, amendments, html) =>

    # Process amendments.
    amendments = if @opts.onlyProcessNth
      [amendments[@opts.onlyProcessNth - 1]]
    else if @opts.onlyProcessFirstN
      _.first amendments, @opts.onlyProcessNth
    else if @opts.onlyProcessRange
      amendments.slice @opts.onlyProcessRange[0] - 1, @opts.onlyProcessRange[1]
    else amendments

    console.log 'Schedule:', schedule
    console.log 'Act:', actTitle

    win = 0
    fail = 0
    total = 0
    _.each amendments, (els) =>
      try
        html = @processAmendment els, html
        win++
      catch e
        fail++
      total++

    console.log "#{win}/#{total} passed"
    console.log "#{parseInt(win/total * 100)}% success rate\n"

    # Return html.
    html

  # Process each item.
  processAmendment: (els, html) =>
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

    prepareAction = ->
      action = $(els[1]).html()
      #action = action.replace /\n/g, ' '
      #$ = cheerio.load action
      ## Unwrap spans.
      #$('span').each -> $(@).replaceWith $(@).html()
      action

    line1 = $(els[0]).text().replace /\n/g, ' '

    try
      amendmentJson = parser.parse
        line1: $(els[0]).text()
        line2: prepareAction()
        line3: prepareBody()
    catch e
      logger.error "Error parsing amendment", e
      console.log "✗ #{line1} (Parse Error)".red
      throw e

    amendment = new Amendment amendmentJson

    # Applies the amendment to some html and returns the new html.
    try
      html = amendment.apply html
      console.log "✔ #{line1}".green
    catch e
      logger.error "Error applying amendment", e
      console.log "✗ #{line1} (Apply Error)".red
      throw e

    return html

  toMarkdown: (html, cb) =>

    converter = new Converter html,
      #root: 'body'
      outputSplit: false
      outputDebug: false
      justMd: true
      cleanTables: true
      linkifyDefinitions: false
      url: "http://www.comlaw.gov.au/Details/C2012C00837/Html"
    converter.getHtml (e) ->
      return cb e if e
      converter.convert cb
