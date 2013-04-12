# This file is for messing around with.

# Vendor.
path = require 'path'
fs = require 'fs'
chai = require 'chai'
chai.should()
_ = require 'underscore'

# Libs.
{Converter} = require '../index.coffee'
{fixtures, fixturesDir, defaultOpts, getFileInfo} = require './helpers'

opts = defaultOpts

# DEBUG: Choose which act you want to convert.
#act = fixtures.marriageAct
#act = fixtures.agedCareAct
#act = fixtures.fairWorkAct2009Vol1
act = fixtures.incomeTaxAssessmentAct1997

main = (done) ->
  _.extend opts, act.opts
  file = getFileInfo act
  _.extend opts, fileMappings: file.fileMappings

  #styleMappings = require path.join fixturesDir, act.styleMappings
  # _.extend opts, mappings: styleMappings

  html = fs.readFileSync file.path
  converter = new Converter html.toString(), _.extend opts,
    fileName: file.name
    url: "http://www.comlaw.gov.au/Details/#{file.base}/Html"
    linkifyDefinitions: false
  converter.getHtml (e) =>
    return done e if e
    converter.convert (e) ->
      return done e if e
      done()

main (e) ->
  throw e if e
