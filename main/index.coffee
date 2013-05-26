# Logging.
require('./logging')()

program = require 'commander'
pjson = require './package.json'

program
  .version(pjson.version)
  .usage("<command> [options]")
program._name = './run'

require('./commands/single')(program)
require('./commands/all')(program)
require('./commands/amend')(program)
require('./commands/test')(program)

# Run.
program.parse(process.argv)
unless program.args.length
  program.outputHelp()
