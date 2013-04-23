# Parses an item.
PEG = require 'pegjs'

class @Parser

  constructor: (grammar) ->
    @parser = PEG.buildParser grammar

  parse: (item) =>
    @parser.parse item
