iced.catchExceptions()

logger = require('onelog').get()

# Vendor.
cheerio = require 'cheerio'
_ = require 'underscore'
xpath = require 'xpath'
dom = require('xmldom').DOMParser
inspect = require('eyes').inspector {maxLength: false}
{parseString} = require 'xml2js'
xamel = require 'xamel'
errTo = require 'errto'
moment = require 'moment'

# Libs.
Model = require('./model')()

class @Parser

  # Given an XML hansard document from OpenAustralia,
  # return a json representation.
  @getHansard: (xml, done) ->
    $ = cheerio.load xml, xmlMode: true
    els = $('debates > *')

    ret =
      units: []
      divisions: []
      # JSON representation of a session, for rendering a session page.
      session: {}
      bills: {}

    context =
      major: null
      majorEl: null
      minor: null
      minorEl: null
      unit: null
      unitEl: null
      # Units since last minor-heading or division.
      # These speeches are relevant to a division because they preceeded it.
      speeches: []

    # Current position in context object.
    pos = null

    # Traverse hansard top-level elements.
    # The hansard is a flattened hierarchical structure.
    for el in els
      $el = $(el)
      name = $el[0].name
      print = true
      indent = null
      switch name

        when 'major-heading'
          context.major = $el.text().trim()
          context.majorEl = $el
          # Reset.
          context.minor = null
          context.speeches = []
          # ---
          indent = 0
          pos = ret.session[$el.text().trim()] or= {}
          pos.$ = $el.attr()

        when 'minor-heading'
          context.minor = $el.text().trim()
          context.minorEl = $el
          # Reset.
          context.unit = null
          context.speeches = []
          # ---
          indent = 2
          pos = ret.session[context.major][$el.text().trim()] or= {}
          pos.$ = $el.attr()

        when 'speech', 'division'
          context.unit = $el
          context.unitEl = $el
          context
          indent = 4
          print = false

          # Session
          # -------
          pos = ret.session[context.major][context.minor]
          unit =
            content: $el.html()
            $: $el.attr()
          pos.units or= []
          pos.units.push unit
          # ---

          # Unit
          # ----
          completeUnit =
            $: $el.attr()
            content: $el.html()
            majorHeading: context.major
            minorHeading: context.minor
          ret.units.push completeUnit
          # ---

          #
          # Speech
          # ------
          #

          if name is 'speech'

            # SpeakerId
            await Model.Member.findOrCreate
              name: completeUnit.$.speakername
            .done errTo done, defer speaker

            # MajorId
            await Model.Major.findOrCreate
              title: completeUnit.majorHeading
            .done errTo done, defer major

            # MinorId
            await Model.Minor.findOrCreate
              title: completeUnit.minorHeading
            .done errTo done, defer minor

            console.log speaker.id
            await Model.Speech.create
              content: $el.html()
              duration: completeUnit.$.approximate_duration
              wordcount: completeUnit.$.approximate_wordcount
              xmlId: completeUnit.$.id
              talktype: completeUnit.$.talktype
              aphUrl: completeUnit.$.url
              # FK.
              speakerId: speaker.id
              majorId: major.id
              minorId: minor.id
              # Denorm.
              speakerName: completeUnit.$.speakername
              # Other.
              json: JSON.stringify {}
            .done errTo done, defer speech

            context.speeches.push speech

          #
          # Division
          # --------
          #

          if name is 'division'

            await parseString $el.toString(), {explicitArray: false}, errTo done, defer dJson

            # MajorId
            await Model.Major.findOrCreate
              title: completeUnit.majorHeading
            .done errTo done, defer major

            # MinorId
            await Model.Minor.findOrCreate
              title: completeUnit.minorHeading
            .done errTo done, defer major

            # Combine date/time.
            date = dJson.division.$.divdate
            time = dJson.division.$.time
            console.log "#{date} #{time}"
            datetime = moment("#{date} #{time}", 'YYYY-MM-DD HH:mm').toDate()

            # Shortcuts.
            divisioncount = dJson.division.divisioncount.$

            # Save Division.
            await Model.Division.create
              # Division
              date: datetime
              divNumber: dJson.division.$.divnumber
              aphUrl: dJson.division.$.url
              nospeaker: dJson.division.$.nospeaker
              xmlId: dJson.division.$.id
              # Division Count
              ayes: divisioncount.ayes
              noes: divisioncount.ayes
              pairs: divisioncount.pairs
              tellerayes: divisioncount.tellerayes
              tellernoes: divisioncount.tellernoes
              # Calculated majority
              majority: Parser.getMajority divisioncount
              # Other
              json: JSON.stringify
                speeches: context.speeches
              # FK.
              majorId: major.id
              minorId: minor.id
            .done errTo done, defer division

            # DivisionSpeech: Division 1-M Speech (join table).
            for speech in context.speeches
              await Model.DivisionSpeech.create
                divisionId: division.id
                speechId: speech.id
              .done errTo done, defer divisionSpeech

            # A separate list for ayes and noes.
            membervotes = Parser.processMemberLists dJson.division.memberlist
            , divisioncount

            # DivisionMember: Division M-M Members.
            for vote in membervotes

              # MemberId.
              await Model.Member.findOrCreate
                name: vote.voterName
              .done errTo done, defer member

              await Model.DivisionMember.create
                vote: vote.vote
                majority: vote.majority
                xmlId: vote.xmlId
                # Denorm.
                voterName: vote.voterName
                # FK.
                memberId: member.id
                divisionId: division.id
              .done errTo done, defer divisionMember

            ret.divisions.push division

            # Reset.
            context.speeches = []
            # ---

      # Print tree structure.

      indent = ' '.repeat(indent)
      if print
        console.log "#{indent}#{name} -> #{$el.text().trim().first(100)}"

    done null, ret


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
