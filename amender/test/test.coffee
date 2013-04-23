# Logging.
onelog = require 'onelog'
log4js = require 'log4js'
onelog.use onelog.Log4js
logger = onelog.get 'Amender Test'
#log4js.configure
#  appenders: [
#    {
#      type: 'console'
#      category: ['Amender Test', 'Amendment', 'AmendmentParser']
#    }
#  ]
#log4js.configure
#  appenders: [
#    {
#      type: 'console'
#      category: ['Amender Test', 'Amendment', 'AmendmentParser']
#      layout:
#        type: 'pattern'
#        pattern: "%m%n"
#    }
#  ]

log4js.setGlobalLogLevel 'OFF'

# Vendor.
fs = require 'fs'
path = require 'path'
util = require 'util'
require 'colors'

# Chai.
chai = require 'chai'
chai.Assertion.showDiff = false # Mocha support is broken, does not respect this option.
chai.should()
expect = chai.expect

# Libs.
{Amender} = require '../index'
{Parser} = require '../parser'
{AmendmentParser} = require '../amendmentParser'
{Converter} = require '../../comLawToMarkdown'

# Helpers.
fixturesDir = '/Users/Vaughan/dev/opendemocracy-fixtures/amender'
fixture = (dir, p) -> path.join fixturesDir, dir, p
read = (file, format = 'utf-8') -> fs.readFileSync file, format

# Diff.
#diffTool = 'ksdiff'
diffTool = 'compare2'
diffCmd = (a, b, c) ->
  if c?
    "#{diffTool} #{a} #{b} #{c} -3 -swap".cyan
  else
    "#{diffTool} #{a} #{b} -swap".cyan
#diffCmd = (a, b, c) -> "#{diffTool} #{a} #{b} #{c if c? else ''}".cyan

# Grammar.
headerGrammar = './grammar/header.pegjs'
actionGrammar = './grammar/action.pegjs'


# Entire Act Tests
# ================

generateMdFromHtml = (html, cb) ->
  converter = new Converter html,
    # For aged care amendment act.
    root: 'body'
    convertEachRootTagSeparately: true
    outputSplit: false
    outputDebug: false
    justMd: true
    cleanTables: true
    linkifyDefinitions: false
    url: "http://www.comlaw.gov.au/Details/C2012C00837/Html"
  converter.getHtml (e) ->
    return cb e if e
    converter.convert cb

fixtures =
  'marriage-equality-amendment-act-2013':
    actDir: 'marriage-equality-amendment-act-2013'
  'aged-care-amendment-act-2011':
    actDir: 'aged-care-amendment-act-2011'

#
recode = (file) ->
  {Iconv} = require 'iconv'
  str = fs.readFileSync file
  iconv = new Iconv 'ISO-8859-1', 'UTF-8'
  buffer = iconv.convert str
  ret = buffer.toString()
  ret = ret.replace /[ÒÓ]/g, '"'
  ret = ret.replace /Õ/g, ' '
  ret = ret.replace /&#8209;/g, '-'
  #ret = ret.replace /&#146;/g, '\''
  ret

# opts.recode will convert from 'ISO-8859-1' to 'UTF-8' and replace
# a few problematic characters.
testEntireAct = (fixtureKey, opts, done) ->
  unless done? then done = opts; opts = {}
  actDir = fixtures[fixtureKey].actDir
  #actMd = read fixture actDir, 'before.md'
  actHtmlPath = fixture actDir, 'before-original.html'
  #actHtml = read actHtmlPath
  actHtml = recode actHtmlPath
  if opts.recode
    amendment = recode fixture actDir, 'amend.html'
  else
    amendment = read fixture actDir, 'amend.html'
  expectedHtmlPath = fixture actDir, 'after.html'
  expectedPath = fixture actDir, 'after.md'
  beforePath = fixture actDir, 'before.md'
  actualPath = path.join __dirname, 'testOutput', 'after-actual' + '.md'
  actualModifiedOriginalHtmlPath = path.join __dirname, 'testOutput', 'after-actual' + '.html'
  actualIntermediateHtmlPath = path.join __dirname, 'testOutput', 'after-actual-inter' + '.html'
  act =
    #markdown: actMd
    #html: actHtml
    originalHtml: actHtml

  printDiff = ->
    console.log """
--------------------------------------------------------------------------------
Regression detected.

1. Inspect Markdown diff (merge changes if they are expected):
  #{diffCmd actualPath, expectedPath}

  #{diffCmd actualPath, expectedPath, beforePath}

2. Inspect original HTML diff (original html > modified html > intermediate html):
  #{diffCmd actHtmlPath, actualModifiedOriginalHtmlPath, actualIntermediateHtmlPath}

--------------------------------------------------------------------------------
"""

  finish = (expected) =>
    @amender.amend act, amendment,
      #onlyProcessRange: [8, 9]
      onlyProcessRange: null
    , (e, md, html) =>
      return done e if e
      fs.writeFileSync actualPath, md, 'utf8'
      fs.writeFileSync actualModifiedOriginalHtmlPath, html, 'utf8'
      fs.writeFileSync actualIntermediateHtmlPath, html, 'utf8'
      logger.debug "Wrote to", actualPath
      logger.debug "Wrote to", actualModifiedOriginalHtmlPath
      logger.debug "Wrote to", actualIntermediateHtmlPath
      unless md is expected
        printDiff()
        return done new Error 'Regression detected.'
      done()

  # Generate original act as markdown.
  # We can compare the after-actual.md to see what has actually changed.
  if opts.generateBeforeMd and not fs.existsSync beforePath
    beforeHtml = read fixture actDir, 'before-original.html'
    generateMdFromHtml beforeHtml, (e, beforeMd) ->
      return done e if e
      fs.writeFileSync beforePath, beforeMd

  # Only generate markdown fixture if it doesn't already exist.
  if opts.generateExpectedMd and not fs.existsSync expectedPath
    expectedHtml = read expectedHtmlPath
    generateMdFromHtml expectedHtml, (e, expectedMd) ->
      return done e if e
      fs.writeFileSync expectedPath, expectedMd
      finish expectedMd
  else
    expectedMd = read expectedPath
    finish expectedMd


describe 'Integration', ->

  before ->
    @amender = new Amender

  it 'Marriage Equality Amendment Bill 2013', (done) ->
    testEntireAct.call @, 'marriage-equality-amendment-act-2013',
      generateExpectedMd: false
    , done

  it 'Aged Care Amendment Act 2011', (done) ->
    testEntireAct.call @, 'aged-care-amendment-act-2011',
      generateExpectedMd: true
      generateBeforeMd: true
      recode: true
    , done

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
