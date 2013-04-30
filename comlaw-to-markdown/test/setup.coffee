# Logging config.
require('./logging')()
logger = require('onelog').get 'ComLawToMarkdown'

# Vendor.
path = require 'path'
fs = require 'fs'
_ = require 'underscore'

# Libs.
{Converter} = require '../index.coffee'
{fixtures, fixturesDir, defaultOpts, getFileInfo} = require './helpers'

# ---

opts = defaultOpts
outputDir = path.join __dirname, 'out/singleFile'

#difftool = 'opendiff'
difftool = 'ksdiff'
difftool = 'compare2'
editor = 'lime'
markdownPreviewTool = 'open -a Marked.app'
diffCmd = (a, b) ->
  "#{difftool} #{a} #{b}"
  #"#{difftool} #{a} #{b} -merge #{expectedMdPath}"

@setup = (act, done) ->
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

@convert = (expectedMdFile, done) ->
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
  #{diffCmd expectedMdPath, generatedMdPath}

2. Inspect rendered Markdown in Marked.app or browser:
  #{markdownPreviewTool} #{generatedMdPath}
  open #{generatedMdHtmlPath}

3. Inspect original HTML in browser (what the rendered Markdown should resemble).
  open #{originalHTMLPath}

4. Inspect cleaned HTML in text editor:
  #{editor} #{cleanedHTMLPath}

5. If the changes are expected, copy generated file to fixtures dir or merge with diff tool from above:
  cp #{generatedMdPath} #{expectedMdPath}
--------------------------------------------------------------------------------
"""
      return done new Error "Regression detected."
    done()
