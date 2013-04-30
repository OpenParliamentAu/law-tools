module.exports = (program) ->

  allCmdDescription = 'Scrapes all act series from http://comlaw.gov.au/ and commits them to a single Git repo one by one.'
  allCmd = program
    .command('all')
    .usage("arg='[options] <phase>'")
    .description(allCmdDescription)
    .action (phase, command) ->
      unless command? then arguments[0].outputHelp(); process.exit()
      unless phase? then program.outputHelp(); process.exit()

      {FederalLawScraper} = require '../all'
      unless FederalLawScraper[phase]? then command.outputHelp(); process.exit()
      console.log 'Running:', phase
      await FederalLawScraper[phase] defer e
      throw e if e
      console.log 'Finished running:', phase

  allCmd.on '--help', ->
    console.log """
    \
      #{allCmdDescription}

      Phases:

        phase1  Retrieve list of all consolidated acts and their ComLawIds from AustLII.
        phase2  Download meta-data and files for each act series.
        phase3  Convert all acts to Markdown.
        phase4  Create git repo. ~5mins

      Examples:

        make arg='all phase1'

      """
