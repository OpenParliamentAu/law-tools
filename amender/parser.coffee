# Parses an item.
PEG = require 'pegjs'

class @Parser

  constructor: (grammar) ->
    @parser = PEG.buildParser grammar

  parse: (item) =>
    try
      @parser.parse item
    catch e
      console.error e
      throw e
