logger = require('onelog').get 'AmendmentParser'

{Parser} = require './parser'

# For parsing a single amendment item.
class @AmendmentParser

    # @option grammar [String] header grammar for extracting affected unit and itemNo.
    # @option grammar [String] action grammar for extracting the action.
    constructor: (@grammar) ->

    parse: (item) =>
      amendment = {}
      # Replace unwanted chars.
      item.line1 = item.line1.replace /\n/, ' '
      logger.debug 'Parsing header:', item.line1
      parser = new Parser @grammar.header
      header = parser.parse item.line1
      amendment.itemNo = header.itemNo
      amendment.unit = header.unit
      # If we have a header which does not reference a unit.
      if amendment.unit.nonUnitHeader?
        amendment.action = null
        amendment.body = item.line2
        return amendment

      logger.debug 'Parsing action:', item.line2
      parser = new Parser @grammar.action
      amendment.action = parser.parse item.line2
      amendment.action.position = header.position if header.position?
      amendment.body = item.line3
      amendment
