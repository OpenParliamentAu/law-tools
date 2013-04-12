# This file is for messing around with.

# Vendor.
path = require 'path'
fs = require 'fs'
chai = require 'chai'
chai.should()
_ = require 'underscore'

# Libs.
{Converter} = require '../index.coffee'
helpers = require './helpers'

# Helpers.
getAllFixturesForAct = (actSlug) ->
  fs.readdirSync path.join fixturesDir, actSlug

opts =
  cheerio: true
  outputSplit: true
  outputDebug: true
  linkifyDefinitions: false
  debugOutputDir: path.join __dirname, 'tmp/singleFile'
  markdownSplitDest: path.join __dirname, 'tmp/multipleFiles/'
  #disabledFilters: ['definition']

  # Use this when you have multiple sections in the document.
  convertEachRootTagSeparately: true

# TODO: Change this to environment var or something.
fixturesDir = path.resolve '/Users/Vaughan/dev/opendemocracy-fixtures'

# All paths in this hash are joined with the fixtures dir.
fixtures =
  marriageAct:
    htmlFile: 'marriage-act-1961/C2012C00837.html'
    fileMappings: 'marriage-act-1961/2012-files.coffee'
    styleMappings: 'marriage-act-1961/2012-styles.coffee'
    opts: {}
  agedCareAct:
    htmlFile: 'aged-care-act-1997/C2012C00914.osxword.htm'
    fileMappings: 'aged-care-act-1997/2012-files.coffee'
    styleMappings: 'aged-care-act-1997/2012-styles.coffee'
    # DEBUG: Change the root to restrict how much markdown is generated.
    opts:
      root: '.WordSection3'
      convertEachRootTagSeparately: false

main = (done) ->

  # DEBUG: Choose which act you want to convert.
  act = fixtures.marriageAct
  #act = fixtures.agedCareAct

  _.extend opts, act.opts
  htmlFilePath = path.join fixturesDir, act.htmlFile
  htmlBaseName = path.basename htmlFilePath, '.html'
  htmlFileNameWithExt = path.basename htmlFilePath
  fileMappings = require path.join fixturesDir, act.fileMappings
  styleMappings = require path.join fixturesDir, act.styleMappings

  html = fs.readFileSync htmlFilePath
  converter = new Converter html.toString(), _.extend opts,
    fileName: htmlFileNameWithExt
    url: "http://www.comlaw.gov.au/Details/#{htmlBaseName}/Html"
    fileMappings: fileMappings
    mappings: styleMappings
  converter.getHtml (e) =>
    return done e if e
    converter.convert (e) ->
      return done e if e
      done()

main (e) ->
  throw e if e
