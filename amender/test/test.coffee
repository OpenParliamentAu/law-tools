fs = require 'fs'
path = require 'path'
util = require 'util'

chai = require 'chai'
chai.Assertion.showDiff = false # Mocha support is broken, does not respect this option.
chai.should()
expect = chai.expect

{Amender} = require '../index'
{Parser} = require '../parser'

fixturesDir = path.join __dirname, 'fixtures'
fixture = (p) -> path.join fixturesDir, p
diffTool = 'ksdiff'
diffCmd = (actual, expected) -> "#{diffTool} #{actual} #{expected}"

describe 'Amender - Integration', ->

  before ->
    @amender = new Amender

  it 'Marriage Equality Amendment Bill 2013', (done) ->
    fileName = 'C2012C00837'
    actMd = fs.readFileSync fixture("#{fileName}-before.md"), 'utf-8'
    actHtml = fs.readFileSync fixture("#{fileName}-before.html"), 'utf-8'
    amendment = fs.readFileSync fixture("#{fileName}-amend.html"), 'utf-8'
    expectedPath = fixture("#{fileName}-after.md")
    expected = fs.readFileSync expectedPath, 'utf-8'
    actualPath = path.join __dirname, 'testOutput', fileName + '.md'
    act =
      markdown: actMd
      html: actHtml
    @amender.amend act, amendment, (e, md) =>
      return done e if e
      fs.writeFileSync actualPath, md, 'utf8'
      console.log "Wrote to", actualPath
      unless md is expected
        console.log diffCmd actualPath, expectedPath
        return done new Error 'Not the same'
      done()

parse = (str, print) ->
  try
    ast = @parser.parse str
    if print then console.log '\n', util.inspect ast, false, null
    ast[0]
  catch e
    console.error e
    throw e

describe 'Amender - Unit', ->

  describe 'marriage equality amendment act 2013', ->

    before ->
      grammar = fs.readFileSync './grammar.pegjs', 'utf-8'
      @parser = new Parser grammar

    it '1', ->
      ast = parse.call @, """
        1 Subsection 5(1)(2) (definition of marriage)
        Repeal the definition, substitute:
        marriage means the union of two people, to the exclusion of all others, voluntarily entered into for life.
        """
      expected =
        itemHeading:
          itemNo: "1"
          unit:
            unitType: "Subsection"
            unitNo: "5"
            subUnitNos: ["1", "2"]
            unitDescriptor: "definition of marriage"
        action:
          line:
            action: "repeal+substitute"
          body: "marriage means the union of two people, to the exclusion of all others, voluntarily entered into for life."
      ast.should.eql expected

    it '2', ->
      ast = parse.call @, """
        2  Subsection 45(2)
        After “or husband”, insert “, or partner”.
        """
      expected =
        itemHeading:
          itemNo: "2"
          unit:
            unitType: "Subsection"
            unitNo: "45"
            subUnitNos: ["2"]
            unitDescriptor: ""
        action:
          line:
            action: 'insert'
            position: "After"
            subject: "or husband"
            object: ", or partner"
          body: ""
      ast.should.eql expected

    it '3', ->
      ast = parse.call @, """
        3  Subsection 46(1)
        Omit “a man and a woman”, substitute “two people”.
        """
      expected =
        itemHeading:
          itemNo: "3"
          unit:
            unitType: "Subsection"
            unitNo: "46"
            subUnitNos: ["1"]
            unitDescriptor: ""
        action:
          line:
            action: "omit+substitute"
            omit: "a man and a woman"
            substitute: "two people"
          body: ""
      ast.should.eql expected

    it '6', ->
      ast = parse.call @, """
        6  Section 88EA
        Repeal the section.
        """
      expected =
        itemHeading:
          itemNo: "6"
          unit:
            unitType: "Section"
            unitNo: "88EA"
            subUnitNos: []
            unitDescriptor: ""
        action:
          line:
            action: "repeal"
          body: ""
      ast.should.eql expected

        #4  Section 47
        #After “Part”, insert “or in any other law”.
        #5  Subsection 72(2)
        #After “or husband”, insert “, or partner”.

        #7  Part III of the Schedule (table item 1)
        #Omit “a husband and wife”, substitute “two people”.
        #"""
