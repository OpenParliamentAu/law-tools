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
errTo = require 'errto'

# Libs.

{Members} = require '..'

describe 'Member Scraper', ->

  before ->

  it 'scrapes Senator Simon Birmingham', (done) ->
    await Members.scrapeMember 'H6X', errTo done, defer data
    console.log data
    #data.should.eql fixtures
    done()
