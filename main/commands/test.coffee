module.exports = (program) ->

  program
    .command('test')
    .usage("[options]")
    .description('Run Mocha tests')
    .action (command) ->
      runMochaFromLib command

runMochaFromLib = (command) ->
  Mocha = require 'mocha'
  path = require 'path'
  mocha = new Mocha
    reporter: 'list'
    timeout: 60000
  p = path.resolve __dirname, '../test/amend.coffee'
  console.log p
  mocha.addFile p
  mocha.run (failures) ->
    process.exit failures
