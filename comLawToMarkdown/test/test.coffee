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

convert = ->


describe 'The converter', ->

  describe 'should not introduce regressions in', ->

    describe 'marriage-act-1961', ->

      before (done) ->
        setup.call @, fixtures.marriageAct, done

      it 'when converting C2012C00837.html', (done) ->
        @converter.convert (e, md) ->
          return done e if e
          expected = fs.readFileSync path.join(fixturesDir, 'marriage-act-1961/C2012C00837.md'), 'utf8'
          #console.log md.slice 0, 100
          #console.log '---------'
          #console.log expected.slice 0, 100
          md.should.equal expected
          done()

    describe 'aged-care-act-1997', ->

      before (done) ->
        setup.call @, fixtures.agedCareAct, done

      it 'when converting C2012C00914.osxword.htm', (done) ->
        @converter.convert (e, md) ->
          return done e if e
          expected = fs.readFileSync path.join(fixturesDir, 'aged-care-act-1997/C2012C00914.osxword.md'), 'utf8'
          md.should.equal expected
          done()

    describe 'fair-work-act-2009', ->

      before (done) ->
        setup.call @, fixtures.fairWorkAct2009Vol1, done

      it 'when converting C2012C00914.osxword.htm', (done) ->
        @converter.convert (e, md) ->
          return done e if e
          expected = fs.readFileSync path.join(fixturesDir, 'fair-work-fact-2009/C2013C00070VOL01.md'), 'utf8'
          md.should.equal expected
          done()

    #describe 'income-tax-assessment-act-1997', ->
    #
    #  before (done) ->
    #    setup.call @, fixtures.incomeTaxAssessmentAct1997, done
    #
    #  it 'when converting C2013C00070VOL01.htm', (done) ->
    #    @converter.convert (e, md) ->
    #      return done e if e
    #      expected = fs.readFileSync path.join(fixturesDir, 'income-tax-assessment-act-1997/C2013C00082VOL01.md'), 'utf8'
    #      md.should.equal expected
    #      done()
