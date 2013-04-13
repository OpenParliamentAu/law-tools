fs = require 'fs'

chai = require 'chai'
chai.should()

{Amender} = require '../index'

describe 'Amender', ->

  before ->
    @amender = new Amender

  it 'Marriage Equality Amendment Bill 2013', ->
    amendment = fs.readFileSync path.join __dirname, 'fixtures/C2012C00837-before.md'
    @amender.amend act

