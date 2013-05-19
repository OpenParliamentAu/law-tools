require 'sugar'

# Logging.
logger = require('onelog').get 'Test'

# Chai.
chai = require 'chai'
chai.Assertion.showDiff = false # Mocha support is broken, does not respect this option.
chai.should()
expect = chai.expect

# Vendor.
inspect = require('eyes').inspector {maxLength: false, depth: 1}
path = require 'path'
fs = require 'fs'
util = require 'util'
_ = require 'underscore'
errTo = require 'errto'

# Libs.
require '../util'

# Constants.
dir = path.join process.env.OPENPARL_FIXTURES, 'voting-record/data.openaustralia.org'
file = dir + '/scrapedxml/senate_debates/2013-02-06.xml'

# Helpers.
printDivisions = (divisions) ->
  for d in divisions
    console.log '\n'
    for speech in d.hansardJSON
      util.print speech.talktype.charAt(0) + ' '
    util.print '\n'
    console.log d.hansardJSON.last().content.first(100)
    if not speech.talktype? then console.log speech

describe 'Parse', ->

  {Parser} = require '../parser'

  before (done) ->
    Model = require('../model')()
    await Model.dropAndSync errTo done, defer()
    @xml = fs.readFileSync file, 'utf8'
    done()

  it 'should get all divisions', (done) ->
    await Parser.parse @xml, errTo done, defer divisions
    printDivisions divisions
    done()

  it 'should get all hansard', (done) ->
    await Parser.getHansard @xml, errTo done, defer()
    done()


