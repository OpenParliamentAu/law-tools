logger = require('onelog').get 'Amendment'

# Vendor.
cheerio = require 'cheerio'
_ = require 'underscore'
fs = require 'fs'
path = require 'path'

# Helpers.
require './util/helpers'
{Finders} = require './util/finders'

# Maps unit types to classes used in `html`.
unitMappings =
  'chapter': 'chapter' # not right!
  'part': 'ActHead2'
  'division': 'division'
  'section':  'ActHead5'
  'subsection': 'subsection'
  'subparagraph': 'paragraphsub'
  'subdivision': 'ActHead4'
  'paragraph': 'paragraph'
  'clause': 'ActHead5'

# All unit referencing starts at section.
units = [
  'chapter', 'part', 'division', 'subdivision', 'section', 'subsection',
  'paragraph', 'subparagraph', 'clause'
]

# For mapping string to methods in `Action` class.
actionMap =
  'repeal+substitute': 'repealAndSubstitute'
  'omit+substitute': 'omitAndSubstitute'
  'insert': 'insert'
  'repeal': 'repeal'
  'simpleInsert': 'simpleInsert'

class @Amendment

  constructor: (@amendment, @opts) ->
    _.defaults @opts, {}

  apply: (html) =>
    logger.debug 'Applying action:', @amendment.action
    unit = @amendment.unit

    # Skip non-unit header for now.
    return html if unit.nonUnitHeader?

    $ = cheerio.load html

    action = @amendment.action
    action.type = actionMap[@amendment.action.type]

    logger.trace unit

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

        when 'subdivision'
          # TODO: CharSubdNo includes `subdivision` text.
          el = $('.ActHead4').findUnitFromInnerSelector '.CharSubdNo', currentUnit.number, 'Subdivision'
          els = $(el).getElementsUntilClass 'ActHead4'

        when 'part'
          el = Finders.findSubUnit $, els, currentUnit.number, 'ActHead2'
          els = $(el).getElementsUntilClass 'ActHead2'

        when 'schedule'
          chapters = $('.ActHead1').filter ->
            text = $(@).find('.CharChapNo').text()
            if currentUnit.number
              text is 'Schedule ' + currentUnit.number
            else
              text is 'The Schedule'
          el = chapters[0]
          els = $(el).getElementsUntilClass 'ActHead1'
        when 'section', 'clause'
          el = $('.ActHead5').findUnitFromInnerSelector '.CharSectno', currentUnit.number
          els = $(el).getElementsUntilClass 'ActHead5'

        when 'subsection'
          _unitType = 'subsection'

          # We are working with a range of subsections.
          # TODO: This is similar to paragraph. Extract to util.
          range = currentUnit.number.range
          array = currentUnit.number instanceof Array
          if range? or array
            numbers = if range?
              _.range range.from, range.to
            else if array
              currentUnit.number
            multiple = true
            affected = []
            for number in numbers
              el = Finders.findSubUnit $, els, number, _unitType
              pels = $(el).getElementsUntilClass _unitType
              affected.push {el: el, els: pels}
            break

          # Now that we have this section's elements. Find subUnitNo.
          el = Finders.findSubUnit $, els, currentUnit.number, _unitType

          # If we don't find the subsection, it might not be numbered
          # because it is the only one. (They sometimes do this).
          subsections = $(els).filter -> $(@).hasClass(_unitType)
          el = subsections[0] if subsections.length is 1

          # This will get any `subsection2` tags. These are just differently
          # formatted subsections.
          els = $(el).getElementsUntilClass _unitType


          if not els.length and not el?
            # We have not found the subsection. It might actually be a
            # section reference, because the subsection was not included in the
            # numbering.

            currentUnit.type = 'section'
            stack.push currentUnit
            break

        when 'paragraph'

          oldEls = els
          multiple = false
          find = (_unitType, _els) ->
            # Multiple paragraphs.
            if currentUnit.number instanceof Array
              multiple = true
              affected = []
              for number in currentUnit.number
                el = Finders.findSubUnit $, _els, number, _unitType
                pels = $(el).getElementsUntilClass _unitType
                affected.push {el: el, els: pels}
            else
              el = Finders.findSubUnit $, _els, currentUnit.number, _unitType
              els = $(el).getElementsUntilClass _unitType

          find 'paragraph', els

          unless el?
            # Could be a BoxPara.

            # BoxPara is surrounded in a classless border. We add its children
            # to our array of elements we will search.
            aEls = []
            _.each oldEls, (item) ->
              unless item.attr('class')?
                for child in $(item).children()
                  aEls.push child
              else
                aEls.push item
            #console.log $(aEls).map -> $.html @
            find 'BoxPara', aEls


    # Process descriptor.
    # i.e. (definition of marriage)
    unitDescriptor = if unit.ofUnit?
      unit.unit.unitDescriptor
    else
      unit.unitDescriptor

    # Definition?
    definition = unitDescriptor?.match(/definition of (.*)/)?[1]
    if definition?
      definitionEl = Finders.findDefinition $, els, definition
      if action.type is 'repealAndSubstitute'
        $(definitionEl).html @amendment.body

    # TODO: Check more descriptors.
    #   Descriptors reduce ambiguity in some cases.

    else

      makeChange = (el, els) =>

        #logger.trace "Before:"
        #logger.trace Amendment.formatElAndContents $, el, els

        # No descriptor, run action on el/els.
        switch action.type
          when 'repealAndSubstitute'
            if multiple
              # Insert before.
              $(affected[0].el).before @amendment.body
              # Remove everything.
              for a in affected
                $(a.el).remove()
                $(a.els).each -> $(@).remove()
            else
              $(els).each -> $(@).remove()
              $(el).replaceWith @amendment.body
            break
          when 'simpleInsert'
            Amendment.simpleInsert $, el, els, @amendment.body, action.position.toLowerCase()
          when 'insert'
            Amendment.insert $, el, els, action, action.position.toLowerCase()
          when 'omitAndSubstitute'
            Amendment.omitAndSubstitute $, el, els, action
          when 'simpleOmit'
            Amendment.simpleOmit $, el, els, action
          when 'repeal'
            if multiple
              for a in affected
                $(a.el).remove()
                $(a.els).each -> $(@).remove()
            else
              Amendment.repeal $, el, els, action
            # TODO: Remove table of contents.

        #logger.trace "After:"
        #logger.trace Amendment.formatElAndContents $, el, els

      makeChange el, els

    return $.html()

  @formatElAndContents: ($, el, els) ->
    str = $(el).html()
    $(els).each -> str += $(@).html()
    str

  @repeal: ($, el, els, action) ->
    $(el).remove()
    $(els).each -> $(@).remove()

  @simpleOmit: ($, el, els, action) ->
    $(el).html $(el).html().replace action.omit, ''
    $(els).each -> $(@).html $(@).html().replace action.omit, ''

  @omitAndSubstitute: ($, el, els, action) ->
    $(el).html $(el).html().replace action.omit, action.substitute
    $(els).each -> $(@).html $(@).html().replace action.omit, action.substitute

  @simpleInsert: ($, el, els, html, where) ->
    # If no position is specified - insert in alphabetical order.
    # This is from a Word Note from the OLPC.
    # TODO: Only for definitions perhaps?
    #console.log $(els).map -> $(@).text()
    if where is ''
      idx = _.sortedIndex els, $(html).text().trim(), (item) ->
        return item if typeof item is 'string'
        if $(item).hasClass 'Definition'
          $(item).text().trim()
        else
          'ZZZZZZZ'
      logger.debug 'Inserting',  $(html).text().trim()
      logger.debug 'at', idx-1
      logger.debug 'after', $(els[idx-1]).text().trim()
      $(els[idx-1]).after '\n\n' + html
      return

    html = '\n\n' + html
    if els.length
      $(els).last()[where] html
    else
      $(el)[where] html

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
