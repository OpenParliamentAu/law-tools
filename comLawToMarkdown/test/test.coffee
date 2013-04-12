# Vendor.
path = require 'path'
fs = require 'fs'
chai = require 'chai'
chai.should()
_ = require 'underscore'

# Libs.
{Converter} = require '../index.coffee'
{fixtures, fixturesDir, defaultOpts, getFileInfo} = require './helpers'

# Logging config.
onelog = require 'onelog'
onelog.getLibrary().setGlobalLogLevel 'WARN'

opts = defaultOpts

describe 'The converter', ->

  describe 'should not introduce regressions to the marriage-act-1961', ->

    before (done) ->
      act = fixtures.marriageAct
      _.extend opts, act.opts
      file = getFileInfo act
      _.extend opts, fileMappings: file.fileMappings
      @html = fs.readFileSync file.path
      @converter = new Converter @html.toString(), _.extend opts,
        fileName: file.name
        url: "http://www.comlaw.gov.au/Details/#{file.base}/Html"
      @converter.getHtml (e) =>
        return done e if e
        done()

    it 'when converting C2012C00837.html', (done) ->
      @converter.convert (e, md) ->
        return done e if e
        expected = fs.readFileSync path.join(fixturesDir, 'marriage-act-1961/C2012C00837.md'), 'utf8'
        #console.log md.slice 0, 100
        #console.log '---------'
        #console.log expected.slice 0, 100
        md.should.equal expected
        done()
