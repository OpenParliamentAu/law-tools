logger = require('onelog').get 'Amendment'

# Vendor.
cheerio = require 'cheerio'
_ = require 'underscore'
fs = require 'fs'
path = require 'path'

class @Action



class @Amendment

  constructor: (@amendment, @opts) ->
    #_.defaults @opts,

  # Statics
  # -------

  @findSubUnit: ($, els, unitNo, className) ->
    #logger.trace 'Searching in:', $(els).map -> $(@).text()
    subUnits = _.filter els, (el) -> $(el).hasClass className
    #logger.trace 'Matching class:', $(subUnits).map -> $(@).text()
    target = _.find subUnits, (el) ->
      text = $(el).text().trim()
      #logger.trace 'Matching text:', ///^\(#{unitNo}\)///, text
      if typeof unitNo is 'object'
        text.match ///#{unitNo.roman}///
      else
        text.match ///^\(#{unitNo}\)///
    #logger.trace 'Match:', target
    target

  # Get all elements up until an element with the same class name is
  # found or end of siblings.
  @getElementsUntilClass = ($, startEl, className) ->
    curr = $(startEl)
    prev = null
    els = []
    while curr?
      prev = curr
      curr = curr.next()
      unless curr.length and curr isnt prev
        curr = null
      else
        els.push curr
        if curr.hasClass className
          curr = null
    logger.debug "Found #{els.length} elements before next #{className} or last sibling"
    els

  @findSection: ($, sectionNo) ->
    sections = $('.ActHead5')
    sections = sections.filter ->
      _sectionNo = $(@).find('.CharSectno').text()
      _sectionNo is sectionNo
    sections[0]

  @findDefinition: ($, els, definition) ->
    _.find els, (el) ->
      return unless $(el).hasClass('Definition')
      defns = $(el).find('b > i')
      res = defns.filter ->
        $(@).text() is definition
      res[0]

  # ---

  apply: (html) =>
    logger.debug 'Applying action:', @amendment.action
    unit = @amendment.unit
    $ = cheerio.load html

    # For mapping string to methods in `Action` class.
    actionMap =
      'repeal+substitute': 'repealAndSubstitute'
      'omit+substitute': 'omitAndSubstitute'
      'insert': 'insert'
      'repeal': 'repeal'

    action = @amendment.action
    action.type = actionMap[@amendment.action.type]

    # Maps unit types to classes used in `html`.
    unitMappings =
      'part': 'part'
      'division': 'division'
      'section':  'ActHead5'
      'subsection': 'subsection'
      'subparagraph': 'paragraphsub'

    # All unit referencing starts at section.
    units = [
      'chapter', 'part', 'division', 'section', 'subsection', 'paragraph', 'subparagraph'
    ]

    logger.trace unit

    # Skip non-unit header for now.
    if unit.nonUnitHeader?
      return $.html()

    # The last `subUnitNo` will always refer to a unit of type `unitType`.
    unitType = unit.unitType.toLowerCase()

    # To determine what unit we should start searching at we start at the
    # `unitType` and keep moving up through the levels until we run out of unitNos.
    indexOfUnitType = _.indexOf units, unitType
    subUnitNosLength = if unit.subUnitNos? then unit.subUnitNos.length else 0
    indexOfStartingType = indexOfUnitType - subUnitNosLength
    unitNos = []; unitNos.push unit.unitNo
    if unit.subUnitNos?
      unitNos = unitNos.concat unit.subUnitNos

    # Create stack of all units we will search through.
    stack = []
    for i in [indexOfStartingType..indexOfUnitType]
      stack.push
        type: units[i]
        number: unitNos[i - indexOfStartingType]

    stack = stack.reverse()

    # If this is of the form: `unitType Y of X`, we add to front of stack.
    if unit.ofUnit?
      stack.push
        type: unit.unit.unitType
        number: unit.unit.unitNo

    logger.trace stack

    # Process stack.
    el = null # The most recent element for unit.
    els = [] # The most recent elements inside unit.
    while stack.length
      currentUnit = stack.pop()
      logger.debug "Finding #{currentUnit.type}", currentUnit.number
      switch currentUnit.type.toLowerCase()
        when 'part'
          el = Amendment.findSubUnit $, els, currentUnit.number, 'ActHead2'
          els = Amendment.getElementsUntilClass $, el, 'ActHead2'
        when 'schedule'
          chapters = $('.ActHead1').filter ->
            $(@).find('.CharChapNo').text() is 'The Schedule'
          el = chapters[0]
          els = Amendment.getElementsUntilClass $, el, 'ActHead1'
        when 'section'
          el = Amendment.findSection $, currentUnit.number
          #console.log $(el).map -> $(@).text()
          els = Amendment.getElementsUntilClass $, el, 'ActHead5'
        when 'subsection'
          # Now that we have this section's elements. Find subUnitNo.
          el = Amendment.findSubUnit $, els, currentUnit.number, 'subsection'
          # This will get any `subsection2` tags. These are just differently
          # formatted subsections.
          els = Amendment.getElementsUntilClass $, el, 'subsection'

    # Process descriptor.
    # i.e. (definition of marriage)
    unitDescriptor = if unit.ofUnit?
      unit.unit.unitDescriptor
    else
      unit.unitDescriptor

    # Definition?
    definition = unitDescriptor?.match(/definition of (.*)/)?[1]
    if definition?
      definitionEl = Amendment.findDefinition $, els, definition
      if action.type is 'repealAndSubstitute'
        $(definitionEl).html @amendment.body

    # TODO: Check more descriptors.
    #   Descriptors reduce ambiguity in some cases.

    else
      logger.trace "Before:"
      logger.trace Amendment.formatElAndContents $, el, els

      # No descriptor, run action on el/els.
      switch action.type
        when 'repealAndSubstitute'
          break
        when 'insert'
          Amendment.insert $, el, els, action, action.position.toLowerCase()
        when 'omitAndSubstitute'
          Amendment.omitAndSubstitute $, el, els, action
        when 'repeal'
          Amendment.repeal $, el, els, action
          # TODO: Remove table of contents.

      logger.trace "After:"
      logger.trace Amendment.formatElAndContents $, el, els

    return $.html()

  @formatElAndContents: ($, el, els) ->
    str = $(el).html()
    $(els).each -> str += $(@).html()
    str

  @repeal: ($, el, els, action) ->
    $(el).remove()
    $(els).each -> $(@).remove()

  @omitAndSubstitute: ($, el, els, action) ->
    $(el).html $(el).html().replace action.omit, action.substitute
    $(els).each -> $(@).html $(@).html().replace action.omit, action.substitute

  @insert: ($, el, els, action, where) ->
    newStr = if where is 'after'
      Amendment.combine action.subject, action.object
    else if where is 'before'
      Amendment.combine action.object, action.subject
    $(el).html $(el).html().replace action.subject, newStr
    $(els).each -> $(@).html $(@).html().replace action.subject, newStr

  @combine: (a, b) ->
    unless b.match /^[,]/ # starts with `,`
      a + ' ' + b
    else
      a + b

  handleOfUnit: ($) =>
    unit = @amendment.unit

    # First find target unit.

    console.log unit
    $.html()
