findAllJson = ->


class @Model

  @sequelize: null
  @Member: null
  @Division: null
  @MemberVote: null
  @sequelize: null

  @init: (done) ->
    # Mongoose
    #mongoose = require 'mongoose'
    #mongoose.connect 'mongodb://localhost/op-voting-record'
    #person = mongoose.model 'Person',
    #  votes: Schema.Types.Mixed

    # Sequelize
    Sequelize = require 'sequelize'
    @sequelize = new Sequelize 'op-voting-record', 'postgres', null,
      dialect: 'postgres'
      host: 'localhost'
      port: 5432
      define:
        underscored: false

    @Member = @sequelize.define 'member',
      name: Sequelize.STRING
      json: Sequelize.TEXT

    @Division = @sequelize.define 'division',
      bill: Sequelize.STRING
      majority: Sequelize.INTEGER
      minority: Sequelize.INTEGER
      yes: Sequelize.INTEGER
      no: Sequelize.INTEGER
      json: Sequelize.TEXT

    @MemberVote = @sequelize.define 'memberVote',
      vote: Sequelize.STRING

    @Division.hasMany @MemberVote
    @Member.hasMany @MemberVote
    @MemberVote.belongsTo @Division
    @MemberVote.belongsTo @Member

    done()

  @sync: (done) ->

    await @sequelize.drop().done defer e
    return done e if e
    await @sequelize.sync().done defer e
    return done e if e

    done()
