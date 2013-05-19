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
      define:
        underscored: false

    define = (args...) => @sequelize.define args...

    @Member = define 'member',
      name:       S.STRING
      json:       S.TEXT

    @Speech = define 'speech',
      content:    S.TEXT
      duration:   S.INTEGER
      wordcount:  S.INTEGER
      xmlId:      S.TEXT
      talktype:   S.STRING
      aphUrl:     S.TEXT
      # FK.
      speakerId:  S.INTEGER
      majorId:    S.INTEGER
      minorId:    S.INTEGER
      # Denorm.
      speakerName: S.TEXT
      # Other.
      json:       S.TEXT

    @Major = define 'major',
      title:      S.TEXT

    @Minor = define 'minor',
      title:      S.TEXT

    @Division = define 'division',
      # Division
      date:       S.DATE
      divNumber:  S.INTEGER
      aphUrl:     S.STRING
      nospeaker:  S.BOOLEAN
      xmlId:      S.TEXT
      # Division Count
      ayes:       S.INTEGER
      noes:       S.INTEGER
      pairs:      S.INTEGER
      tellerayes: S.INTEGER
      tellernoes: S.INTEGER
      # Calculated majority
      majority:   S.INTEGER
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
