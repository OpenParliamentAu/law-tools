_ = require 'underscore'
cheerio = require 'cheerio'
moment = require 'moment'
errTo = require 'errto'

Model = require('./model')()

class @Division

  @parse: (division, context, done) ->
    # Get speeches leading up to this division.
    to = division.$.order
    precedingSpeeches = context.speechModels[0..to-1]
    precedingSpeechesAsJson = precedingSpeeches.map (s) -> s.values

    datetime = Division.extractTime division, context

    divisioncount =
      ayes: division['division.data'].ayes['num.votes']
      noes: division['division.data'].noes['num.votes']
      pairs: division['division.data'].pairs['num.votes']

    # Save Division.
    await Model.Division.create
      # Division
      date: datetime
      preamble: division['division.header'].body # TODO: Should be parse?
      result: division['division.result'].body
      # Division Count
      ayes: divisioncount.ayes
      noes: divisioncount.noes
      pairs: divisioncount.pairs
      # Calculated majority
      majority: Division.getMajority divisioncount
      # Denorm
      majorTitle: context.major?.title
      minorTitle: context.minor?.title
      # Other
      json: JSON.stringify
        speeches: precedingSpeechesAsJson
      # FK.
      majorId: context.major?.id
      minorId: context.minor?.id
    .done errTo done, defer dbDivision

    for speech in precedingSpeeches
      # TODO: Check that the speech did not involve a vote/question because
      #   every vote does not require a division.

      # DivisionSpeech: Division 1-M Speech (join table).
      await Model.DivisionSpeech.create
        divisionId: dbDivision.id
        speechId: speech.id
      .done errTo done, defer divisionSpeech

    # Votes.
    await Division.parseMemberVotes division, divisioncount, errTo done, defer()

    done()

  @parseMemberVotes: (division, divisioncount, done) ->

    # A separate list for ayes and noes.
    memberVotes = Division.processMemberLists division['division.data'], divisioncount

    # DivisionMember: Division M-M Members.
    for mv in memberVotes

      # MemberId.
      await Model.Member.findOrCreate
        name: mv.voterName
      .done errTo done, defer member

      await Model.DivisionMember.create
        vote: mv.vote
        majority: vm.majority
        # Denorm.
        voterName: vm.voterName
        # FK.
        memberId: member.id
        divisionId: division.id
      .done errTo done, defer divisionMember

    done()

  @extractTime: (division, context) ->
    divisionHeaderHtml = division['division.header'].body
    $ = cheerio.load divisionHeaderHtml
    txt = $('p.HPS-DivisionPreamble').text()
    [matches, time] = txt.match /\[(\d{2}:\d{2})\]/
    date = context.session.date
    #console.log "#{date} #{time}"
    datetime = moment("#{date} #{time}", 'YYYY-MM-DD HH:mm').toDate()
    datetime

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

  @processMemberLists: (divisionData, divisioncount) ->
    memberVotes = []
    # k = ayes, noes, pairs
    for k, v of divisionData
      names = v.names
      vote = switch k
        when 'ayes' then 1
        when 'noes' then -1
        when 'pairs' then 0
      for name in names
        memberVotes.push
          vote: vote
          voterName: name
          majority: Division.isMajority divisioncount, vote
    return memberVotes

# Get map of member -> vote
#isFor = (vote) ->
#  switch vote
#    when 'aye' then 1
#    when 'no' then -1
#    when 'nay' then -1
#    else vote
