module.exports = (program) ->

  singleCmdDescription = 'Scrapes a series of acts from http://comlaw.gov.au/ and creates a Git repo from them.'
  singleCmd = program
    .command('single')
    .usage("[options] <comLawId>")
    .description(singleCmdDescription)
    .option('-s, --single-repo', 'Create repo containing only one act')
    .option('-n, --number-of-acts <n>', 'Max number of acts from the series to scrape', parseInt)
    .option('-d, --debug', 'Show debugging log messages')
    .action (comLawId, command) ->
      # Print usage if comLawId not provided.
      unless command? then arguments[0].outputHelp(); process.exit()
      examples = require('../single')
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
