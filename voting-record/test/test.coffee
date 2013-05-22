iced.catchExceptions()
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
myutil = require '../util'

# Helpers.
printDivisions = (divisions) ->
  for d in divisions
    console.log '\n'
    for speech in d.hansardJSON
      util.print speech.talktype.charAt(0) + ' '
    util.print '\n'
    console.log d.hansardJSON.last().content.first(100)
    if not speech.talktype? then console.log speech

describe 'OpenAustralia XML Parse', ->

  {Parser} = require '../oa/parser'

  before (done) ->
    Model = require('../oa/model')()
    await Model.dropAndSync errTo done, defer()
    @xml = myutil.readFixture 'data.openaustralia.org/scrapedxml/senate_debates/2013-02-06.xml'
    done()

  it 'should get all divisions', (done) ->
    await Parser.parse @xml, errTo done, defer divisions
    printDivisions divisions
    done()

  it 'should get all hansard', (done) ->
    await Parser.getHansard @xml, errTo done, defer()
    done()


describe 'OAXML Parser', ->

  {OAXML} = require '../aph/oaxml'

  before (done) ->
    Model = require('../aph/model')()
    await Model.dropAndSync errTo done, defer()

  it 'should work', (done) ->
    oaxml = new OAXML
    await oaxml.toDb errTo done, defer()
    done()

# Use original XML from http://aph.gov.au.
describe 'APH XML Parse', ->

  {Parser} = require '../aph/parser'

  before (done) ->
    Model = require('../aph/model')()
    await Model.dropAndSync errTo done, defer()
    # To compare output visit the same session on OA.
    # http://www.openaustralia.org/senate/?id=2013-02-06.6.1
    @xml = myutil.readFixture 'data.openaustralia.org/origxml/senate_debates/2013-02-06.xml'
    done()

  it 'should process hansard', (done) ->
    parser = new Parser
    await parser.parse @xml, errTo done, defer()
    done()
