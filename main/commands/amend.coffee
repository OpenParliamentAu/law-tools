module.exports = (program) ->

  amendDescription = 'Scrape an amendment, apply to a consolidated act, commit to repo.'
  amendCmd = program
    .command('amend')
    .usage("[options] <amendment-bill-id>")
    .description(amendDescription)
    .action (amendmentBillId, command) ->
      unless command? then arguments[0].outputHelp(); process.exit()
      {AmendRunner} = require '../amend'
      AmendRunner.amend amendmentBillId, ->
        process.exit()

  amendCmd.on '--help', ->

    console.log """
    \
      #{amendDescription}

      amendment-bill-id   Bill ID from http://www.aph.gov.au (e.g. r4943)

      """
