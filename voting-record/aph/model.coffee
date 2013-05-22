errTo = require 'errto'
S = Sequelize = require 'sequelize'
_ = require 'underscore'
uuid = require 'node-uuid'
extend = require 'xtend'

DAOFactory = require 'sequelize/lib/dao-factory'

model = null
module.exports = ->
  unless model?
    model = new Model
    model.init()
  return model

# Helpers.
idType = S.INTEGER
oaIdType = S.STRING

class Model

  init: =>
    # Mongoose
    #mongoose = require 'mongoose'
    #mongoose.connect 'mongodb://localhost/op-voting-record'
    #person = mongoose.model 'Person',
    #  votes: Schema.Types.Mixed

    @sequelize = new Sequelize 'op-voting-record', 'postgres', null,
      dialect: 'postgres'
      host: 'localhost'
      port: 5432
      logging: false
      #logging: console.log
      omitNull: true
      define:
        underscored: false

    define = (tableName, mod, opts = {}) =>
      _.extend mod,
        uuid: {type: S.STRING, allowNull: true}
      opts.classMethods or= {}
      _.extend opts.classMethods,
        create: (attrs, args...) ->
          _.extend attrs, uuid: uuid.v4()
          return DAOFactory::create.call @, attrs, args...

      @sequelize.define tableName, mod, opts

    @Session = define 'session',
      date:         S.DATE
      parliamentNo: S.INTEGER
      sessionNo:    S.INTEGER
      periodNo:     S.INTEGER
      chamber:      S.STRING
      pageNo:       S.INTEGER
      proof:        S.INTEGER

    @SessionJson = define 'sessionJson',
      json:         S.TEXT
      # FK.
      sessionId:    idType

    @Party = define 'party',
      name:         S.TEXT

    # Member enums.
    enteredHouseReasonEnum = S.ENUM 'general_election', 'changed_party'
    , 'by_election', 'reinstated', 'section_15'

    leftHouseReasonEnum = S.ENUM 'general_election', 'still_in_office', 'died'
    , 'changed_party', 'general_election_standing'
    , 'general_election_not_standing', 'disqualified'
    , 'resigned', 'declared_void', 'became_peer', 'retired'
    , 'elected_elsewhere', 'defeated', 'term_expired'

    # Records membership.
    @Member = define 'member',
      json:       S.TEXT
      # OA.
      firstName:  S.STRING
      lastName:   S.STRING
      constituency: S.STRING
      party:      S.STRING
      house:      S.STRING
      enteredHouse:  S.STRING
      enteredReason: enteredHouseReasonEnum
      leftHouse:     S.STRING
      leftReason:    leftHouseReasonEnum
      title:      S.STRING
      oaId:       oaIdType
      # FK.
      personId:   idType
      partyId:    idType
    , {
      classMethods:

        # Format: <lastname>, <initials> (teller)
        # E.g.
        #   Polley, H (teller)
        #   Boswell, RLD
        #
        # TODO: We need to get their initials too because its the only way
        #   to unambigously match them from divisions.
        #
        findByNameFromDivision: (name, house) ->
          matches = name.match /([\S\s]+), (\S*)(\s\(teller\))?/
          [match, lastName, initials, teller] = matches
          return @find
            where:
              lastName: lastName
              house: house

        # From element `speech/talk.start/talker/name`
        # Format: <lastname>, <abbreviated-title> <initials>
        # E.g.
        #   <name role="metadata">Farrell, Sen Don</name>
        #
        # Can also be a title like:
        #
        #   DEPUTY PRESIDENT, The
        #
        findByNameFromHansard: (name) ->
          # TODO: HACKY!!!
          # Check for titles.
          if name.indexOf('DEPUTY PRESIDENT') isnt -1
            return {done: (done) -> done null, null}
          else if name.indexOf('PRESIDENT') isnt -1
            return {done: (done) -> done null, null}

          matches = name.match /([\S\s]+), (\S+) (\S+)/
          [match, lastName, title, firstName] = matches
          return @find
            where:
              lastName: lastName
              firstName: firstName

        #   <span class="HPS-MemberSpeech">Senator BIRMINGHAM</span>
        #   <span class="HPS-Electorate">South Australia</span>
        #
        #   <span class="HPS-MemberContinuation">Senator BIRMINGHAM:</span>
        #   <span class="HPS-MemberInterjecting">Senator Farrell:</span>
        findByNameFromHansardBody: (name) ->

      instanceMethods:

        getFullName: ->
          return @firstName + ' ' + @lastName
    }

    @Speech = define 'speech',
      date:       S.DATE
      content:    S.TEXT
      hasChairQuestion: S.BOOLEAN
      # FK.
      speakerId:  idType
      majorId:    idType
      minorId:    idType
      stageId:    idType
      # Denorm.
      electorate: S.STRING
      ministerialTitles: S.STRING
      speakerName: S.STRING
      party:      S.STRING
      mpid:       S.STRING # aph.gov.au MP id
      # Other.
      json:       S.TEXT

    @Major = define 'major',
      title:      S.TEXT
      type:       S.STRING

    @Minor = define 'minor',
      title:      S.TEXT
      type:       S.STRING

    # E.g. In Committee, Second Reading, etc.
    @Stage = define 'stage',
      title:      S.TEXT

    @Division = define 'division',
      # Division
      date:       S.DATE
      preamble:   S.TEXT
      result:     S.TEXT
      divided:    S.BOOLEAN # Was there a division for the question put to the house.
      # Division Count
      ayes:       S.INTEGER
      noes:       S.INTEGER
      pairs:      S.INTEGER
      # Majority/Minority
      majority:   S.INTEGER
      minority:    S.INTEGER
      # Calculated majority
      difference: S.INTEGER
      majorityVote: S.INTEGER
      # Denorm
      majorTitle: S.STRING
      minorTitle: S.STRING
      # Other
      json:       S.TEXT
      # FK.
      majorId:    idType
      minorId:    idType

    @DivisionSpeech = define 'divisionSpeech',
      divisionId: idType
      speechId:   idType

    @DivisionMember = define 'divisionMember',
      vote:       S.INTEGER
      majority:   S.BOOLEAN
      xmlId:      S.TEXT
      # Denorm.
      voterName:  S.STRING
      # FK.
      memberId:   idType
      divisionId: idType

    @Constituency = define 'constituency',
      name:       S.STRING
      # OA.
      oaId:       S.STRING

    @MemberOffice = define 'memberOffice',
      toDate:     S.DATE
      fromDate:   S.DATE
      name:       S.STRING
      position:   S.TEXT
      # FK.
      memberId:   idType
      # OA.
      oaId:       oaIdType
      oaMemberId: oaIdType

    @Person = define 'person',
      latestName: S.STRING
      oaId:       oaIdType
      json:       S.TEXT

    #@Bill = define 'bill',
    #  json:       S.STRING

    #@Division.hasMany @MemberVote
    #@Member.hasMany @MemberVote
    #@MemberVote.belongsTo @Division
    #@MemberVote.belongsTo @Member

  sync: (done) =>
    @sequelize.sync().done done

  drop: (done) =>
    @sequelize.sync().done done

  dropAndSync: (done) =>
    noErr = errTo.bind null, done
    await @sequelize.drop().done noErr defer()
    await @sequelize.sync().done noErr defer()
    done()

  dropAndSyncSpecificModels: (models, done) =>
    noErr = errTo.bind null, done
    for m in models
      await @[m].sync(force: true).done noErr defer()
    done()



