_ = require 'underscore'

class @Finders

  @findDefinition: ($, els, definition) ->
    _.find els, (el) ->
      return unless $(el).hasClass('Definition')
      defns = $(el).find('b > i')
      res = defns.filter ->
        $(@).text() is definition
      res[0]

  @findSubUnit: ($, els, unitNo, className) ->
    #logger.trace 'Searching in:', $(els).map -> $(@).text()
    subUnits = _.filter els, (el) -> $(el).hasClass className
    #logger.trace 'Matching class:', $(subUnits).map -> $(@).text()
    target = _.find subUnits, (el) ->
      text = $(el).text()
      text = text.replace /�/g, ' '
      text = text.trim()
      #logger.trace 'Matching text:', ///^\(#{unitNo}\)///, text
      if typeof unitNo is 'object'
        text.match ///#{unitNo.roman}///
      else
        text.match ///^\(#{unitNo}\)///
    #logger.trace 'Match:', target
    target

#getClassNamesAboveUnit = (unit) ->
#  a = _.initial units, _.indexOf(units, unit)
#  a = _.map a, (i) -> unitMappings[i]
#  a
