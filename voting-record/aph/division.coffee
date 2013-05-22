_ = require 'underscore'
cheerio = require 'cheerio'
moment = require 'moment'
errTo = require 'errto'

Model = require('./model')()

class @Division

  # If the chair puts a question to vote which does not get divided.
  @parseQuestion: (speech, context, precedingSpeechModels, done) ->
    noErr = errTo.bind null, done

    precedingSpeechesAsJson = precedingSpeechModels.map (s) -> s.values

    await Model.Division.create
      date: speech.date
      divided: false
      # Denorm
      majorTitle: context.major?.title
      minorTitle: context.minor?.title
      # Other
      json: JSON.stringify
        speeches: precedingSpeechesAsJson
        partySummary: null
        rebelVoters: []
        allVotes: []
      # FK.
      majorId: context.major?.id
      minorId: context.minor?.id
    .done noErr defer dbDivision

    done()


  @parse: (division, context, precedingSpeechModels, done) ->
    noErr = errTo.bind null, done

    precedingSpeechesAsJson = precedingSpeechModels.map (s) -> s.values
    datetime = Division.extractTime division, context

    divisioncount =
      ayes: division['division.data'].ayes['num.votes']
      noes: division['division.data'].noes['num.votes']
      pairs: division['division.data'].pairs['num.votes']

    # Votes.
    await Division.parseMemberVotes division, divisioncount, context
    , noErr defer allVotes, partySummary, rebelVoters

    # Save Division.
    await Model.Division.create
      # Division
      date: datetime
      preamble: division['division.header'].body # TODO: Should be parse?
      result: division['division.result'].body
      divided: true
      # Division Count
      ayes: divisioncount.ayes
      noes: divisioncount.noes
      pairs: divisioncount.pairs
      # Majority/Minority
      majority: Division.voteCount true, divisioncount
      minority: Division.voteCount false, divisioncount
      # Calculated majority
      difference: Division.getDifference divisioncount
      majorityVote: Division.getMajorityVote divisioncount
      # Denorm
      majorTitle: context.major?.title
      minorTitle: context.minor?.title
      # Other
      json: JSON.stringify
        speeches: precedingSpeechesAsJson
        partySummary: partySummary
        rebelVoters: rebelVoters
        allVotes: allVotes

      # FK.
      majorId: context.major?.id
      minorId: context.minor?.id
    .done noErr defer dbDivision

    for speech in precedingSpeechModels
      # DivisionSpeech: Division 1-M Speech (join table).
      await Model.DivisionSpeech.create
        divisionId: dbDivision.id
        speechId: speech.id
      .done noErr defer divisionSpeech

    done()

  @parseMemberVotes: (division, divisioncount, context, done) ->
    noErr = errTo.bind null, done

    # A separate list for ayes and noes.
    memberVotes = Division.processMemberLists division['division.data'], divisioncount

    # Party -> {name, majority, minority, turnoutCount, turnoutPerc}
    partySummary = {}

    # DivisionMember: Division M-M Members.
    for mv in memberVotes

      # MemberId.
      await Model.Member.findByNameFromDivision(mv.voterName, context.session.chamber.toLowerCase())
      .done noErr defer member

      # Add memberModel to member votes because we will use it to work out
      # rebel voters later.
      mv.memberModel = member

      await Model.DivisionMember.create
        vote: mv.vote
        majority: mv.majority
        # Denorm.
        voterName: mv.voterName
        # FK.
        memberId: member.id
        divisionId: division.id
      .done noErr defer divisionMember

      # Update party summary.
      # TODO: Should we use partyId instead?
      partySummary[member.party] or=
        majority: 0
        minority: 0
        turnoutCount: 0
      partySummary[member.party].turnoutCount++
      if mv.majority
        partySummary[member.party].majority++
      else
        partySummary[member.party].minority++

    # Calculate party turnout.
    for partyName, stats of partySummary
      # Get all members of party.
      # TODO: leftReason might not be best.
      await Model.Member.findAll
        where:
          party: partyName
          leftReason: 'still_in_office'
          house: context.session.chamber.toLowerCase()
      .done noErr defer partyMembers
      stats.turnoutPerc = parseInt(stats.turnoutCount) / partyMembers.length

    # Voters who voted against the majority of their party.
    rebelVoters = []
    for mv in memberVotes
      memberPartySummary = partySummary[mv.memberModel.party]
      memberPartyMajority = memberPartySummary.majority > memberPartySummary.minority
      # Majority here is a boolean, meaning whether they voted with the
      # majority of voters.
      if mv.majority isnt memberPartyMajority and not mv.isPair
        # Rebel voter!
        rebelVoters.push
          name: mv.memberModel.getFullName()
          constituency: mv.memberModel.constituency
          memberId: mv.memberModel.id
          party: mv.memberModel.party
          vote: mv.vote

    # Find all members whom are eligible to vote in this division.
    await Model.Member.findAll
      where:
        leftReason: 'still_in_office'
        house: context.session.chamber.toLowerCase()
    .done noErr defer eligib


    allVotes = []
    for mv in memberVotes
      allVotes.push
        name: mv.memberModel.getFullName()
        constituency: mv.memberModel.constituency
        memberId: mv.memberModel.id
        party: mv.memberModel.party
        vote: mv.vote

    done null, allVotes, partySummary, rebelVoters

  @extractTime: (division, context) ->
    divisionHeaderHtml = division['division.header'].body
    $ = cheerio.load divisionHeaderHtml
    txt = $('p.HPS-DivisionPreamble').text()
    [matches, time] = txt.match /\[(\d{2}:\d{2})\]/
    date = context.session.date
    datetime = moment("#{date} #{time}", 'YYYY-MM-DD HH:mm').toDate()
    datetime

  @getMajorityVote: (divisioncount) ->
    ayes = divisioncount.ayes
    noes = divisioncount.noes
    return null if ayes is noes
    if ayes > noes
      return 1
    else if ayes < noes
      return -1
    else
      return null

  @voteCount: (majority, divisioncount) ->
    ayes = divisioncount.ayes
    noes = divisioncount.noes
    if majority
      if ayes > noes then return ayes else return noes
    else
      if ayes > noes then return noes else return ayes

  @isMajority: (divisioncount, vote) ->
    ayes = divisioncount.ayes
    noes = divisioncount.noes
    return null if ayes is noes
    if vote is 1
       return ayes > noes
    else if vote is -1
       return ayes < noes
    else
      return 0

  @getDifference: (divisioncount) ->
    ayes = divisioncount.ayes
    noes = divisioncount.noes
    return Math.abs ayes - noes

  @processMemberLists: (divisionData, divisioncount) ->
    memberVotes = []
    # k = ayes, noes, pairs
    for k, v of divisionData
      if v.names isnt ''
        names = v.names.name
      vote = switch k
        when 'ayes' then 1
        when 'noes' then -1
        when 'pairs' then 0
      for name in names
        memberVotes.push
          vote: vote
          voterName: name
          majority: Division.isMajority divisioncount, vote
          isPair: k is 'pairs'
    return memberVotes

# Get map of member -> vote
#isFor = (vote) ->
#  switch vote
#    when 'aye' then 1
#    when 'no' then -1
#    when 'nay' then -1
#    else vote
