module.exports = (program) ->

  amendDescription = 'Scrape an amendment, apply to a consolidated act, commit to repo.'
  amendCmd = program
    .command('amend')
    .usage("arg='[options] <amendment-bill-id>'")
    .description(amendDescription)
    .action (amendmentBillId, command) ->
      unless command? then arguments[0].outputHelp(); process.exit()
      console.log 'TODO'

  amendCmd.on '--help', ->

    console.log """
    \
      #{amendDescription}

      amendment-bill-id   Bill id from http://aph.gov.au (e.g. r4943)

      """
