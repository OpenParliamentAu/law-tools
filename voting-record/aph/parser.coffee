# Iced.
iced.catchExceptions()

# Logging.
logger = require('onelog').get()

# Vendor.
cheerio = require 'cheerio'
_ = require 'underscore'

# XPATH
xpath = require 'xpath'
{DOMParser, XMLSerializer} = require 'xmldom'

inspect = require('eyes').inspector {maxLength: false}
{parseString} = require 'xml2js'
xamel = require 'xamel'
errTo = require 'errto'
moment = require 'moment'
myutil = require '../util'
util = require 'util'

# Libs.
Model = require('./model')()
{Division} = require './division'
{Speech} = require './speech'

class @Parser

  # Anything in a `body` tag should be treated as HTML, so we wrap in CDATA.
  @encodeTagsAsHTML: (xml) ->
    xml = xml.replace /<body(?!.*\/>)([^>]*)>/gi, '<body$1><![CDATA['
    xml = xml.replace /(<\/body>)/gi, "]]>$1"
    xml

  #
  # We need to preserve the ordering of speeches and divisions so that we can
  # associate a division, with the speeches preceding it.
  #
  # This is required because we are working with JSON object fomr xml2js.
  # This would not be required if the library preserved ordering of children, or
  # if we were traversing the XML DOM.
  #
  @numberSpeechesAndDivisions: (xml) ->
    doc = new DOMParser().parseFromString xml
    debates = xpath.select "//*[self::subdebate.1 or self::subdebate.2]", doc
    for debate in debates
      # Direct descendents of debate element only.
      nodes = xpath.select '*[self::speech or self::division]', debate
      for n, i in nodes
        n.setAttribute 'order', i
        #console.log n.toString()
    str = new XMLSerializer().serializeToString doc
    str

  # Given an XML hansard document from OpenAustralia,
  # return a json representation.
  parse: (xml, done) =>
    noErr = errTo.bind null, done

    context = {}

    # Enclose elements containing HTML as CDATA.
    xml = Parser.encodeTagsAsHTML xml

    # Number speeches and divisions.
    xml = Parser.numberSpeechesAndDivisions xml

    await parseString xml, {explicitArray: false}, noErr defer json

    # Session.
    session = myutil.camelizeKeysExt json.hansard['session.header']
    await Model.Session.create(session).done noErr defer session
    context.session = session

    # Session JSON.
    sessionJson = {json: JSON.stringify(json), sessionId: session.id}
    await Model.SessionJson.create(sessionJson).done noErr defer sessionJson

    # Debates.
    chamberXscript = json.hansard['chamber.xscript']
    businessStart = chamberXscript['business.start']

    for d in _.asArray chamberXscript.debate
      # Major heading.
      major = d.debateinfo.title
      await Model.Major.findOrCreate(title: major).done noErr defer major
      context.major = major

      console.log major.title

      # Are the any speeches?
      for speech in d.speech or []
        await Speech.parse speech, context, noErr defer speech

      for subdebate in _.asArray d['subdebate.1']

        # Minor heading.
        minor = subdebate.subdebateinfo.title
        await Model.Minor.findOrCreate(title: minor).done noErr defer minor
        context.minor = minor

        console.log '  ' + minor.title

        # Speeches.
        for speech in subdebate.speech or []
          await Speech.parse speech, context, noErr defer speech

        for subsubdebate in _.asArray subdebate['subdebate.2']

          # Stage.
          # E.g. Second Reading, In Committee
          stage = subsubdebate.subdebateinfo.title
          await Model.Stage.findOrCreate(title: stage).done noErr defer stage
          context.stage = stage

          console.log "    [#{stage.title}]"

          # Speeches.

          for speech in _.asArray subsubdebate.speech
            speech.$.type = 'speech'

          # Add attribute to mark division as division.
          for division in _.asArray subsubdebate.division
            division.$.type = 'division'

          # We need to associate speeches leading up to a division or question
          # with that question.
          units = []
          units = units.concat _.asArray subsubdebate.speech
          units = units.concat _.asArray subsubdebate.division
          # Sort units by order attribute. (NOTE: The order attribute was added
          # by us)
          units = _.sortBy units, (unit) -> parseInt unit.$.order

          precedingSpeechModels = []
          for unit, i in units

            if unit.$.type is 'division'
              await Division.parse unit, context, precedingSpeechModels, noErr defer division
              precedingSpeechModels = []

            else if unit.$.type is 'speech'
              await Speech.parse unit, context, noErr defer dbUnit
              precedingSpeechModels.push dbUnit

              followedByADivision = ->
                idx = i + 1
                u = units[idx]
                return false unless u?
                u.$.type is 'division'

              # Does this speech contain a question?
              if dbUnit.hasChairQuestion and not followedByADivision()
                await Division.parseQuestion dbUnit, context, precedingSpeechModels, noErr defer division
                precedingSpeechModels = []

    done null, null

  #@addQuestionAttributeToSpeechIfNeccessary: (speech) ->
  #  $ = cheerio.load speech['talk.text'].body._
  #  console.log 'HTML:', $('.OfficeInterjecting').html()
  #  speech.$.question = true

  @isMajority: (divisioncount, vote) ->
    ayes = divisioncount.ayes
    noes = divisioncount.noes
    return null if ayes is noes
    if vote
       return ayes > noes
     else
       return ayes < noes

  @getMajority: (divisioncount) ->
    ayes = divisioncount.ayes
    noes = divisioncount.noes
    return Math.abs ayes - noes

  @processMemberLists: (memberlists, divisioncount) ->
    membervotes = []
    for list in memberlists
      membervotes = membervotes.concat _.map list.member, (vote) ->
        _vote = isFor vote.$.vote
        xmlId: vote.$.id
        vote: _vote
        majority: Parser.isMajority divisioncount, _vote
        voterName: vote._
    return membervotes

#
# Example:
#
#     Maritime Powers Bill 2012, Maritime Powers (Consequential Amendments)
#     Bill 2012; In Committee
#
extractBillTitleAndStage = (heading) ->
  arr = heading.text().split(';')
  _.map arr, (x) -> x.trim().replace('\n', '')

# Get map of member -> vote
isFor = (vote) ->
  switch vote
    when 'aye' then 1
    when 'no' then -1
    when 'nay' then -1
    else vote
