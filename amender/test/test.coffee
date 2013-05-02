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

testGetAmendedActs = (bill, expected, done) ->
  amendmentHtml = helpers.getAmendmentHtml bill
  amender = new Amender amendmentHtml
  acts = amender.getAmendedActs()
  acts.should.eql expected
  done()

describe 'Unit', ->

  it 'get amended acts from Marriage bill', (done) ->
    testGetAmendedActs.call @, 'Marriage Equality Amendment Act 2013'
    , ['Marriage Act 1961'], done

  it 'get amended acts for Aged Care bill', (done) ->
    testGetAmendedActs.call @, 'Aged Care Amendment Act 2011'
    , ['Aged Care Act 1997',
      'Health Insurance Act 1973',
      'National Health Act 1953',
      'Aged or Disabled Persons Care Act 1954',
      'Nursing Home Charge (Imposition) Act 1994']
    , done

describe 'Integration', ->

  before ->

  it 'Marriage Equality Amendment Bill 2013', (done) ->
    helpers.testEntireAct.call @, 'Marriage Equality Amendment Act 2013',
      generateExpectedMd: true
    , done

  it 'Aged Care Amendment Act 2011', (done) ->
    helpers.testEntireAct.call @, 'Aged Care Amendment Act 2011',
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
