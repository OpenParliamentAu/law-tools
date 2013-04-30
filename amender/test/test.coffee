# Logging.
logger = require('onelog').get 'Test'

# Chai.
chai = require 'chai'
chai.Assertion.showDiff = false # Mocha support is broken, does not respect this option.
chai.should()
expect = chai.expect

# Libs.
helpers = require './helpers'
{AmendmentParser} = require '../amendmentParser'
{Amender} = require '../index'

describe 'Integration', ->

  before ->
    @amender = new Amender

  it 'Marriage Equality Amendment Bill 2013', (done) ->
    helpers.testEntireAct.call @, 'marriage-equality-amendment-act-2013',
      generateExpectedMd: true
    , done

  it 'Aged Care Amendment Act 2011', (done) ->
    helpers.testEntireAct.call @, 'aged-care-amendment-act-2011',
      generateExpectedMd: true
      generateBeforeMd: true
      recode: true
    , done

describe 'Parser', ->

  describe 'marriage equality amendment act 2013', ->

    before ->
      grammar =
        header: read headerGrammar
        action: read actionGrammar
      @parser = new AmendmentParser grammar
      @fixtures = require './fixtures/marriage-equality-amendment-act'

    it '#1', ->
      test.call @, 1

    it '#2', ->
      test.call @, 2

    it '#3', ->
      test.call @, 3

    it '#6', ->
      test.call @, 6

    #4  Section 47
    #After “Part”, insert “or in any other law”.
    #5  Subsection 72(2)
    #After “or husband”, insert “, or partner”.

    #7  Part III of the Schedule (table item 1)
    #Omit “a husband and wife”, substitute “two people”.
    #"""
