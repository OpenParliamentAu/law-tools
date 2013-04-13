# Vendor.
path = require 'path'
fs = require 'fs'
chai = require 'chai'
chai.should()
_ = require 'underscore'
html = require 'html'

# Libs.
{Converter} = require '../index.coffee'
{fixtures, fixturesDir, defaultOpts, getFileInfo} = require './helpers'

# Logging config.
onelog = require 'onelog'
onelog.getLibrary().setGlobalLogLevel 'WARN'

opts = defaultOpts

setup = (act, done) ->
  _.extend opts, act.opts
  file = getFileInfo act
  _.extend opts, fileMappings: file.fileMappings
  @html = fs.readFileSync file.path
  @converter = new Converter @html.toString(), _.extend opts,
    fileName: file.name
    url: "http://www.comlaw.gov.au/Details/#{file.base}/Html"
    outputSplit: false
    debugOutputDir: path.join __dirname, 'out/singleFile'
    linkifyDefinitions: false # We don't linkify because it takes too long for testing.
  @converter.getHtml (e) =>
    return done e if e
    done()
  @converter

convert = (expectedMdFile, done) ->
  @converter.convert (e, md) ->
    return done e if e
    expected = fs.readFileSync path.join(fixturesDir, expectedMdFile), 'utf-8'
    md.should.equal expected
    done()

describe 'The converter', ->

  describe 'should not introduce regressions in', ->

    it 'when converting marriage act', (done) ->
      setup.call @, fixtures.marriageAct, =>
        convert.call @, 'marriage-act-1961/C2012C00837.md', done

    it 'when converting aged care act', (done) ->
      setup.call @, fixtures.agedCareAct, =>
        convert.call @, 'aged-care-act-1997/C2012C00914.osxword.md', done

    it 'when converting fair work act', (done) ->
      setup.call @, fixtures.fairWorkAct2009Vol1, =>
        convert.call @, 'fair-work-act-2009/C2013C00070VOL01.md', done

    #it 'when converting income tax assessment act 1997', (done) ->
    #  setup.call @, fixtures.incomeTaxAssessmentAct1997, done
    #  convert.call @, 'income-tax-assessment-act-1997/C2013C00082VOL01.md', done
