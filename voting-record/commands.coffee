# Hooks.
iced.catchExceptions()
require 'sugar'

# Vendor.
program = require 'commander'
pjson = require './package.json'
errTo = require 'errto'

# Libs.
myutil = require './util'
Model = require('./aph/model')()

program
  .version(pjson.version)
  .usage("<command> [options]")
program._name = 'run'

# Commands
# --------

err = (e) ->
  console.error e
  process.exit()

noErr = errTo.bind null, err

desc = 'Drop and sync db schema'
program.command('dropandsync')
  .description(desc)
  .action (command) ->
    await Model.dropAndSync noErr defer()
    console.log 'Dropped and synced db'

desc = 'Sync db schema'
program.command('sync')
  .description(desc)
  .option('-D, --drop', 'Drop database first')
  .action (command) ->
    if command.drop?
      await Model.drop noErr defer()
      console.log 'Dropped db'
    await Model.sync noErr defer()
    console.log 'Synced db'

desc = 'Import members into database'
program.command('members')
  .usage("[options]")
  .description(desc)
  .option('-D, --drop', 'Drop database first')
  .action (command) ->
    if command.drop?
      await Model.dropAndSync noErr defer()
      console.log 'Dropped db'
    {OAXML} = require './aph/oaxml'
    oaxml = new OAXML
    await oaxml.toDb noErr defer()
    console.log 'Member import complete'

desc = 'Import hansard into database'
hansardCmd = program.command('hansard')
  .usage("[options]")
  .description(desc)
  .option('-D, --drop', 'Drop Speeches and Divisions first')
  #.option('-f, --file <file>', 'Path to file to import')
  .action (command) ->
    # TODO: file.
    #return hansardCmd.outputHelp() unless command?
    if command.drop?
      await Model.dropAndSyncSpecificModels ['Speech', 'Division'], noErr defer()
    {Parser} = require './aph/parser'
    parser = new Parser
    xml = myutil.readFixture 'data.openaustralia.org/origxml/senate_debates/2013-02-06.xml'
    await parser.parse xml, noErr defer()
    console.log 'Hansard import complete'

# --------

program.parse(process.argv)
program.outputHelp() unless program.args.length
