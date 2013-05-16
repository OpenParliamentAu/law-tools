# Vendor.
onelog = require 'onelog'
logger = require('onelog').get()
fs = require 'fs'
util = require 'util'
inspect = require('eyes').inspector({maxLength: false})
_ = require 'underscore'
path = require 'path'
walk = require 'walk'

# Libs.
require './util'
{Model} = require './model'
{Parser} = require './parser'

# Constants.
dir = '/Users/Vaughan/dev/opendemocracy-fixtures/voting-record/data.openaustralia.org'
file = dir + '/scrapedxml/senate_debates/2013-03-13.xml'

# Create model.
await Model.init defer e
throw e if e
await Model.sync defer e
throw e if e

sequelize = Model.sequelize
Division = Model.Division
Member = Model.Member
MemberVote = Model.MemberVote

class VotingRecord

  @run: (done) ->

    # Read all files.
    walker  = walk.walk dir, {followLinks: false}
    files = []
    walker.on 'file', (root, stat, next) ->
      files.push root + '/' + stat.name
      next()
    await walker.on 'end', defer()

    # Process each file.
    for file in files
      continue unless path.extname(file) is '.xml'
      #continue unless /2013(.*)/.test path.basename(file)
      continue unless /2013\-03\-13/.test path.basename(file)
      await @parseFile file, defer e, result
      return done e if e
      await @persist result, defer e
      return done e if e

  @parseFile: (file, done) ->
    xml = fs.readFileSync file, 'utf8'
    logger.info 'Processing', file
    await Parser.parse xml, defer e, divisions
    return done e if e
    done null, result

  @persist: (divisions, done) ->

    # Map people to bills
    for d in divisions
      d.billTitle = d.billTitle.replace '\n', ''

      # Create division
      await Division.findOrCreate {bill: d.billTitle},
        bill: d.billTitle
        json: JSON.stringify
          meta: d.meta
          divisioncount: d.divisioncount
          hansard: d.hansard
        majority: d.majority
      .done defer e, dbDivision
      return done e if e

      # Process votes.
      for voter in d.membervotes

        # Create member.
        await Member.findOrCreate(name: voter.name).done defer e, dbMember
        return done e if e

        # Create vote.
        await MemberVote.create(
          vote: voter.vote
          memberId: dbMember.id
          divisionId: dbDivision.id
        ).done defer e, dbMemberVote
        return done e if e

        peopleToBills[voter.name] or= {}
        peopleToBills[voter.name].votes or= []
        peopleToBills[voter.name].votes.push
          bill: bill.billTitle
          vote: voter.vote
          majority: voter.majority

await VotingRecord.run defer e
throw e if e
