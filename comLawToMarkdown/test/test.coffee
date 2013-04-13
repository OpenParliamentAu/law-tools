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
outputDir = path.join __dirname, 'out/singleFile'

setup = (act, done) ->
  _.extend opts, act.opts
  file = getFileInfo act
  _.extend opts, fileMappings: file.fileMappings
  @html = fs.readFileSync file.path
  @converter = new Converter @html.toString(), _.extend opts,
    fileName: file.name
    url: "http://www.comlaw.gov.au/Details/#{file.base}/Html"
    outputSplit: false
    debugOutputDir: outputDir
    linkifyDefinitions: false # We don't linkify because it takes too long for testing.
  @converter.getHtml (e) =>
    return done e if e
    done()
  @converter

convert = (expectedMdFile, done) ->
  @converter.convert (e, md) ->
    return done e if e

    htmlFileName = path.basename(expectedMdFile, '.md') + '.html' # .html
    mdHtmlFileName = path.basename(expectedMdFile) + '.html' # .md.html

    expectedMdPath = path.join fixturesDir, expectedMdFile
    expectedMdText = fs.readFileSync expectedMdPath, 'utf-8'

    originalHTMLPath = path.join path.dirname(expectedMdPath), htmlFileName
    cleanedHTMLPath = path.join outputDir, htmlFileName

    generatedMdPath = path.join outputDir, path.basename expectedMdFile
    generatedMdHtmlPath = path.join outputDir, path.basename mdHtmlFileName
    generatedMdText = md

    if generatedMdText isnt expectedMdText

      console.log """
--------------------------------------------------------------------------------
Regression detected.

1. Inspect Markdown diff (merge changes if they are expected):
  opendiff #{expectedMdPath} #{generatedMdPath} -merge #{expectedMdPath}

2. Inspect rendered Markdown in Marked.app or browser:
  open -a Marked.app #{generatedMdPath}
  open #{generatedMdHtmlPath}

3. Inspect original HTML in browser (what the rendered Markdown should resemble).
  open #{originalHTMLPath}

4. Inspect cleaned HTML in text editor:
  lime #{cleanedHTMLPath}

5. If the changes are expected, copy generated file to fixtures dir:
  cp #{generatedMdPath} #{expectedMdPath}
--------------------------------------------------------------------------------
"""
      return done new Error "Regression detected."
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
