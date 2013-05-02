require('./logging')()
logger = require('onelog').get()

# Chai.
chai = require 'chai'
chai.Assertion.showDiff = false # Mocha support is broken, does not respect this option.
chai.should()
expect = chai.expect

# Vendor.
util = require 'util'
fs = require 'fs'
path = require 'path'

# Libs.
{APH} = require '..'
fixtures = require './fixtures'

ids =
  # Marriage Equality Amendment Bill 2013
  marriage: 's905'
  # Aboriginal and Torres Strait Islander Peoples Recognition Bill 2012
  aboriginal: 'r4943'
  # National Disability Insurance Scheme Bill 2013
  ndis: 'r4946'

getPath = (file) -> path.join process.env['OPENPARL_FIXTURES'], 'aph', file
readFile = (file) -> fs.readFileSync getPath file
readHtmlFromId = (id) -> readFile id + '.html'
print = (obj) -> console.log util.inspect obj, null, depth: null

ndis = {html: readHtmlFromId(ids.ndis)}

describe 'APH', ->

  before ->

  it 'scrapes National Disability Insurance Scheme Bill 2013', (done) ->
    await APH.scrapeBillHomePage ndis, defer e, data
    return done e if e
    #print data
    data.should.eql fixtures
    done()

  it 'downloads first reading of amendment bill', (done) ->
    await APH.downloadFirstReading ndis, defer e, filename
    return done e if e
    exists = fs.existsSync filename
    expect(exists).to.be.true
    done()

  it 'converts Word to HTML', (done) ->
    doc = getPath 's905-first-reading.docx'
    tempPath = APH.copyFileToTempLocation doc
    await APH.convertWordToHTML tempPath, defer e, htmlPath
    return done e if e
    exists = fs.existsSync(htmlPath)
    expect(exists).to.be.true
    done()

  it 'downloads first reading and converts to HTML', (done) ->
    await APH.downloadFirstReadingAndConvertToHTML ndis, defer e, filename
    return done e if e
    exists = fs.existsSync(filename)
    expect(exists).to.be.true
    done()
