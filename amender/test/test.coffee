fs = require 'fs'
path = require 'path'
util = require 'util'

chai = require 'chai'
chai.Assertion.showDiff = false # Mocha support is broken, does not respect this option.
chai.should()
expect = chai.expect

# Libs.
{Amender} = require '../index'
{Parser} = require '../parser'
{AmendmentParser} = require '../amendmentParser'

# Helpers.
fixturesDir = '/Users/Vaughan/dev/opendemocracy-fixtures/amender'
fixture = (dir, p) -> path.join fixturesDir, dir, p
diffTool = 'ksdiff'
diffCmd = (actual, expected) -> "#{diffTool} #{actual} #{expected}"

headerGrammar = './grammar/header.pegjs'
actionGrammar = './grammar/action.pegjs'

read = (file) -> fs.readFileSync file, 'utf-8'

# Entire Act Tests
# ================

describe 'Integration', ->

  before ->
    @amender = new Amender

  it 'Marriage Equality Amendment Bill 2013', (done) ->
    actDir = 'marriage-equality-amendment-act-2013'
    actMd = read fixture actDir, 'before.md'
    actHtml = read fixture actDir, 'before-original.html'
    amendment = read fixture actDir, 'amend.html'
    expectedPath = fixture actDir, 'after.md'
    expected = read expectedPath
    actualPath = path.join __dirname, 'testOutput', 'after-actual' + '.md'
    act =
      markdown: actMd
      #html: actHtml
      originalHtml: actHtml

    @amender.amend act, amendment, (e, md) =>
      return done e if e
      fs.writeFileSync actualPath, md, 'utf8'
      console.log "Wrote to", actualPath
      unless md is expected
        console.log diffCmd actualPath, expectedPath
        return done new Error 'Not the same'
      done()


# Unit Tests
# ==========

parse = (item) ->
  try
    @parser.parse item
  catch e
    console.error e
    throw e

# @param [Boolean] if true, print the parse output to console.
test = (fixtureKey, print = false) ->
  amendment = parse.call @, @fixtures[fixtureKey].item
  if print then console.log '\n', util.inspect amendment, false, null
  amendment.should.eql @fixtures[fixtureKey].expected

describe 'Parser', ->

  describe 'marriage equality amendment act 2013', ->

    before ->
      grammar =
        header: read headerGrammar
        action: read actionGrammar
      @parser = new AmendmentParser grammar
      @fixtures = require './fixtures/marriage-equality-amendment-act'

    it '#1', ->
      test.call @, 1

    it '#2', ->
      test.call @, 2

    it '#3', ->
      test.call @, 3

    it '#6', ->
      test.call @, 6

    #4  Section 47
    #After “Part”, insert “or in any other law”.
    #5  Subsection 72(2)
    #After “or husband”, insert “, or partner”.

    #7  Part III of the Schedule (table item 1)
    #Omit “a husband and wife”, substitute “two people”.
    #"""
