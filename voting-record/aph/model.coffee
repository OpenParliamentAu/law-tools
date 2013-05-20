errTo = require 'errto'
S = Sequelize = require 'sequelize'

model = null
module.exports = ->
  unless model?
    model = new Model
    model.init()
  return model

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
      define:
        underscored: false

    define = (args...) => @sequelize.define args...

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
      sessionId:    S.INTEGER

    @Member = define 'member',
      name:       S.STRING
      # TODO: Electorate.
      json:       S.TEXT

    @Speech = define 'speech',
      date:       S.DATE
      content:    S.TEXT
      # FK.
      speakerId:  S.INTEGER
      majorId:    S.INTEGER
      minorId:    S.INTEGER
      stageId:    S.INTEGER
      # Denorm.
      content:    S.TEXT
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
      # Division Count
      ayes:       S.INTEGER
      noes:       S.INTEGER
      pairs:      S.INTEGER
      # Calculated majority
      majority:   S.INTEGER
      # Denorm
      majorTitle: S.STRING
      minorTitle: S.STRING
      # Other
      json:       S.TEXT
      # FK.
      majorId:    S.INTEGER
      minorId:    S.INTEGER

    @DivisionSpeech = define 'divisionSpeech',
      divisionId: S.INTEGER
      speechId:   S.INTEGER

    @DivisionMember = define 'divisionMember',
      vote:       S.INTEGER
      majority:   S.BOOLEAN
      xmlId:      S.TEXT
      # Denorm.
      voterName:  S.STRING
      # FK.
      memberId:   S.INTEGER
      divisionId: S.INTEGER

    #@Bill = define 'bill',
    #  json:       S.STRING

    #@Division.hasMany @MemberVote
    #@Member.hasMany @MemberVote
    #@MemberVote.belongsTo @Division
    #@MemberVote.belongsTo @Member

  dropAndSync: (done) =>
    await @sequelize.drop().done errTo done, defer()
    await @sequelize.sync().done errTo done, defer()
    done()
