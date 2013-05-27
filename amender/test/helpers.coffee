logger = require('onelog').get 'Amender Test'

# Vendor.
fs = require 'fs'
path = require 'path'
util = require 'util'
_ = require 'underscore'
mkdirp = require 'mkdirp'
temp = require 'temp'

# Libs.
{Parser} = require '../parser'
{Converter} = require 'comlaw-to-markdown'
{Amender} = require '..'

# Helpers.
fixturesDir = path.join process.env['OPENPARL_FIXTURES'], 'amender'
fixture = (dir, p) -> path.join fixturesDir, dir, p
read = (file, format = 'utf-8') ->
  return null unless fs.existsSync file
  fs.readFileSync file, format
testOutputDir = path.join __dirname, 'testOutput'
mkdirp.sync testOutputDir

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
    #root: 'body'
    convertEachRootTagSeparately: true
    outputSplit: false
    outputDebug: false
    justMd: true
    cleanTables: true
    linkifyDefinitions: false
    url: "http://www.comlaw.gov.au/Details/C2012C00837/Html"
  await converter.getHtml defer e
  return cb e if e
  converter.convert cb

fixtures =
  'Marriage Equality Amendment Act 2013':
    actDir: 'Marriage Equality Amendment Act 2013'
  'Aged Care Amendment Act 2011':
    actDir: 'Aged Care Amendment Act 2011'


recode = (file) ->
  return null unless fs.existsSync file
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

@getAmendmentHtml = (fixtureKey) ->
  actDir = fixtures[fixtureKey].actDir
  amendmentHtml = recode fixture actDir, 'amend.html'

printDiff = (title, fixures, actual, done) ->
  actualMarkdownPath = writeTemp actual.markdown, suffix: '_ACTUAL.md'

  # Generate expected Markdown before.
  await generateMdFromHtml fixures.before, defer e, beforeMd
  return done e if e
  beforeMarkdownPath = writeTemp beforeMd, suffix: '_BEFORE.md'

  # Generate expected Markdown after.
  if fixures.expected?
    await generateMdFromHtml fixures.expected, defer e, afterMd
    return done e if e
    expectedMarkdownPath = writeTemp afterMd, suffix: '_EXPECTED.md'
  else
    # Allow for manual Markdown generation.
    expectedMarkdownPath = writeTemp fixures.expectedMarkdown, suffix: '_EXPECTED.md'

  actHtmlPath = writeTemp fixures.before, suffix: '_BEFORE.html'
  actualModifiedOriginalHtmlPath = writeTemp actual.modifiedOriginalHtml, suffix: '_ACTUAL_MODIFIED_ORIGINAL.html'
  actualIntermediateHtmlPath = writeTemp actual.intermediateHtml, suffix: '_ACTUAL_INTERMEDIATE.html'

  console.log """
--------------------------------------------------------------------------------
Regression detected when amending: #{title}

1. Inspect Markdown diff (merge changes if they are expected):
  #{diffCmd actualMarkdownPath, expectedMarkdownPath}

  #{diffCmd actualMarkdownPath, expectedMarkdownPath, beforeMarkdownPath}

2. Inspect original HTML diff (original html > modified html > intermediate html):
  #{diffCmd actHtmlPath, actualModifiedOriginalHtmlPath, actualIntermediateHtmlPath}

--------------------------------------------------------------------------------
"""

  done()

writeTemp = (content, opts) ->
  _.defaults opts, {suffix: null, prefix: null}
  dest = temp.path {suffix: opts.suffix, prefix: opts.prefix}
  fs.writeFileSync dest, content, 'utf8'
  dest

# opts.recode will convert from 'ISO-8859-1' to 'UTF-8' and replace
# a few problematic characters.
@testEntireAct = (fixtureKey, opts, done) ->
  unless done? then done = opts; opts = {}

  # Get fixtures directory for a given amendment act.
  actDir = fixtures[fixtureKey].actDir

  # Read amendment act html.
  if opts.recode
    amendmentHtml = recode fixture actDir, 'amend.html'
  else
    amendmentHtml = read fixture actDir, 'amend.html'

  amender = new Amender amendmentHtml

  # Get html data for all acts which will be amended.
  #
  # This dir is expected to contain all the before and after acts named
  # exactly as they appear in the amendment act.
  #
  # Marriage Act 1961_before.html
  # Marriage Act 1961_after.html
  #
  acts = amender.getAmendedActs()
  actsFixtures = {}
  actsInput = {}
  for title in acts
    # For testing purposes.
    actsFixtures[title] = {}
    actsFixtures[title].before = read fixture actDir, title + '_before.html'
    actsFixtures[title].expected = read fixture actDir, title + '_after.html'
    actsFixtures[title].expectedMarkdown = read fixture actDir, title + '_after.md'
    # For passing to amender.
    actsInput[title] = actsFixtures[title].before

  # Run test.
  await amender.amend actsInput,
    #onlyProcessRange: [8, 9]
    onlyProcessRange: null
  , defer e, actsOutput
  return done e if e

  regression = false
  for title, actOutput of actsOutput
    unless actOutput.modifiedOriginalHtml.localeCompare actsFixtures[title].expected
      #for k,v of actsFixtures[title]
      #  console.log k, v.length
      logger.warn "Regression detected in '#{title}'. Generating diffs..."
      await printDiff title, actsFixtures[title], actOutput, defer e
      return done e if e
      regression = true
  return done(new Error 'Regression detected.') if regression
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
  item = @fixtures[fixtureKey].item
  expected = @fixtures[fixtureKey].expected
  amendment = parse.call @, item
  if print then console.log '\n', util.inspect amendment, false, null
  # The lines which were passed are also returned from the parse function.
  # This makes our fixtures more DRY.
  expected = _.extend item, expected
  # ---
  amendment.should.eql expected
