iced.catchExceptions()

# Vendor.
onelog = require 'onelog'
logger = require('onelog').get()
fs = require 'fs'
util = require 'util'
inspect = require('eyes').inspector({maxLength: false})
_ = require 'underscore'
path = require 'path'
walk = require 'walk'
errTo = require 'errto'

# Libs.
require './util'
{Model} = require './model'
{Parser} = require './parser'
{DB} = require './db'

# Constants.
dir = path.join process.env.OPENPARL_FIXTURES, 'voting-record/data.openaustralia.org'

# Create database.
await DB.initAndSync defer()

{
  sequelize
  Division
  Member
  MemberVote
} = Model

class VotingRecord

  @run: (done) ->

    await @readFiles errTo done, defer files

    # Filter files.
    files = _.filter files, (x) ->
      return false unless /2013-02-06(.*)/.test path.basename(x)
      #return false unless /2013(.*)/.test path.basename(x)
      return false unless path.extname(x) is '.xml'
      return true

    # Process each file.
    for file in files
      await @parseFile file, defer e, divisions
      return done e if e

  @readFiles: (done) ->
    # Read all files.
    walker  = walk.walk dir, {followLinks: false}
    files = []
    walker.on 'file', (root, stat, next) ->
      files.push root + '/' + stat.name
      next()
    await walker.on 'end', defer()
    done null, files

  @parseFile: (file, done) ->
    xml = fs.readFileSync file, 'utf8'
    logger.info 'Processing', file
    await Parser.getHansard xml, errTo done, defer()
    done()

await VotingRecord.run defer e
throw e if e
