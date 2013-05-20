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

    context = {}

    # Enclose elements containing HTML as CDATA.
    xml = Parser.encodeTagsAsHTML xml

    # Number speeches and divisions.
    xml = Parser.numberSpeechesAndDivisions xml

    await parseString xml, {explicitArray: false}, errTo done, defer json

    # Session.
    session = myutil.camelizeKeysExt json.hansard['session.header']
    await Model.Session.create(session).done errTo done, defer session
    context.session = session

    # Session JSON.
    sessionJson = {json: JSON.stringify(json), sessionId: session.id}
    await Model.SessionJson.create(sessionJson).done errTo done, defer sessionJson

    # Debates.
    chamberXscript = json.hansard['chamber.xscript']
    businessStart = chamberXscript['business.start']

    for d in _.asArray chamberXscript.debate
      # Major heading.
      major = d.debateinfo.title
      await Model.Major.findOrCreate(title: major).done errTo done, defer major
      context.major = major

      console.log major.title

      # Are the any speeches?
      for speech in d.speech or []
        await Speech.parse speech, context, errTo done, defer speech

      for subdebate in _.asArray d['subdebate.1']

        # Minor heading.
        minor = subdebate.subdebateinfo.title
        await Model.Minor.findOrCreate(title: minor).done errTo done, defer minor
        context.minor = minor

        console.log '  ' + minor.title

        # Speeches.
        for speech in subdebate.speech or []
          await Speech.parse speech, context, errTo done, defer speech

        for subsubdebate in _.asArray subdebate['subdebate.2']

          # Stage.
          # E.g. Second Reading, In Committee
          stage = subsubdebate.subdebateinfo.title
          await Model.Stage.findOrCreate(title: stage).done errTo done, defer stage
          context.stage = stage

          console.log "    [#{stage.title}]"

          # Speeches.
          context.speechModels = []
          for speech in _.asArray subsubdebate.speech
            await Speech.parse speech, context, errTo done, defer speech
            context.speechModels.push speech

          for division in _.asArray subsubdebate.division
            await Division.parse division, context, errTo done, defer division

    done null, null


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
