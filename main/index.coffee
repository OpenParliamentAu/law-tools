# Logging.
require('./logging')()

program = require 'commander'
pjson = require './package.json'

program
  .version(pjson.version)
  .usage("arg='<command> [options]'")
program._name = 'make'

require('./commands/single')(program)
require('./commands/all')(program)
require('./commands/amend')(program)

# Run.
program.parse(process.argv)
unless program.args.length
  program.outputHelp()
