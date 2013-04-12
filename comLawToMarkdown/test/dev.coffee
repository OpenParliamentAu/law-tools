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
  debugOutputDir: helpers.curdir 'tmp/singleFile'
  markdownSplitDest: helpers.curdir 'tmp/multipleFiles/'
  #disabledFilters: ['definition']

# TODO: Change this to environment var or something.
fixturesDir = path.resolve '/Users/Vaughan/dev/opendemocracy-fixtures'

# All paths in this hash are joined with the fixtures dir.
fixtures =
  marriageAct:
    htmlFile: 'aged-care-act-1997/C2012C00914.osxword.htm'
    fileMappings: 'marriage-act-1961/2012-files.coffee'
    styleMappings: 'marriage-act-1961/2012-styles.coffee'
    opts: {}
  marriageAct:
    htmlFile: 'aged-care-act-1997/C2012C00914.osxword.htm'
    fileMappings: 'aged-care-act-1997/2012-files.coffee'
    styleMappings: 'aged-care-act-1997/2012-styles.coffee'
    opts: {}

main = (done) ->

  # DEBUG: Choose which act you want to convert.
  act = fixtures.marriageAct

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
