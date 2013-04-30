program = require 'commander'
pjson = require './package.json'

class @Main

  @run: ->

    program
      .version(pjson.version)
      .usage("arg='<command> [options]'")
    program._name = 'make'

    # Single
    # ------

    singleCmdDescription = 'Scrapes a series of acts from http://comlaw.gov.au/ and creates a Git repo from them.'
    singleCmd = program
      .command('single')
      .usage("arg='[options] <comLawId>'")
      .description(singleCmdDescription)
      .option('-s, --single-repo', 'Create repo containing only one act')
      .option('-n, --number-of-acts <n>', 'Max number of acts from the series to scrape', parseInt)
      .option('-d, --debug', 'Show debugging log messages')
      .action (comLawId, command) ->
        # Print usage if comLawId not provided.
        unless command? then arguments[0].outputHelp(); process.exit()
        examples = require('./examples')
        examples.run comLawId, command

    singleCmd.on '--help', ->
      console.log """
      \
        #{singleCmdDescription}

        Examples:

          # Create repo for first two acts from Marriage Act 1961
          make arg='single -s -n 2 C1961A00012'

          # A New Tax System Act 1999
          make arg='single C2004A00467'

          # Add first two acts from Aboriginal Affairs as subdirectories in a master repo'.
          make arg='single -n 2 C2004A03898'

        """


    # All
    # ---

    allCmdDescription = 'Scrapes all act series from http://comlaw.gov.au/ and commits them to a single Git repo one by one.'
    allCmd = program
      .command('all')
      .usage("arg='[options] <phase>'")
      .description(allCmdDescription)
      .action (phase, command) ->
        unless command? then arguments[0].outputHelp(); process.exit()
        unless phase? then program.outputHelp(); process.exit()

        {FederalLawScraper} = require './main.coffee'
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
          phase4  Create git repo.

        Examples:

          make arg='all phase1'

        """

    program.parse(process.argv)

    unless program.args.length
      program.outputHelp()

exports.Main.run()
