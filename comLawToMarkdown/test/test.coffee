# Vendor.
path = require 'path'
fs = require 'fs'
chai = require 'chai'
chai.should()

# Libs.
{Converter} = require '../index.coffee'
mappings = require '../styles/styles-2012'

# Fixtures.
htmlFixturesDir = path.join __dirname, 'fixtures/html'
htmlFixtures = fs.readdirSync htmlFixturesDir

# Constants.
_2012 = 'C2012C00837'

# Helpers.
getFixture = (file) -> path.resolve path.join htmlFixturesDir, file + '.html'
curdir = (file) -> path.join __dirname, file

# Setup.

fileMappings =
  '1-info': ['.Section1']
  '2-contents': ['.Section2']
  '3-act': ['.Section3', '.Section4']
  '4-notes': ['.Section5', '.Section6', '.Section7', '.Section8', '.Section9']

opts =
  cheerio: true
  fileName: _2012
  url: "http://www.comlaw.gov.au/Details/#{_2012}/Html"
  #disabledFilters: ['definition']
  mappings: mappings
  fileMappings: fileMappings
  outputSplit: true
  outputDebug: true
  linkifyDefinitions: true
  debugOutputDir: curdir 'tmp/single_file'
  markdownSplitDest: curdir 'tmp/split_files/'

describe 'Microsoft Word HTML to Markdown Converter', ->

  beforeEach (done) ->
    @html = fs.readFileSync getFixture(_2012)
    @converter = new Converter @html.toString(), opts
    @converter.getHtml (e) =>
      return done e if e
      done()

  it 'should run without errors', (done) ->
    @converter.convert (e, html) ->
      return done e if e
      done()
