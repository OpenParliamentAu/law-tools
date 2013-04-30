# Logging.
onelog = require 'onelog'
log4js = require 'log4js'
onelog.use onelog.Log4js
logger = onelog.get()

_ = require 'underscore'
async = require 'async'

{ComLaw} = require 'comlaw-scraper'

marriageAct = 'C1961A00012'

# TODO: Update with links.
fixtures =
  [
    {
      Title: 'Marriage Act 1961\r\n                                                Superseded',
      ComlawId: 'C2004C05246',
      'Date Prepared': '02/Aug/1991',
      'Start Date': '',
      'End Date': '',
      'Incorporating Amendments Up To': 'Act No. 71 of 1991',
      output: path: '/Users/Vaughan/dev/opendemocracy/lib/parser/downloads/comlaw/markdown/C2004C05246.md'
    },
    {
      Title: 'Marriage Act 1961\r\n                                                Superseded',
      ComlawId: 'C2004C05245',
      'Date Prepared': '19/Dec/1973',
      'Start Date': '',
      'End Date': '',
      'Incorporating Amendments Up To': 'Act No. 216 of 1973',
      output: path: '/Users/Vaughan/dev/opendemocracy/lib/parser/downloads/comlaw/markdown/C2004C05245.md'
    }
  ]

mkdirp = require 'mkdirp'
path = require 'path'
fs = require 'fs'
#gitteh = require 'gitteh'

main = ->

  ComLaw.actSeries marriageAct, (e, acts) =>
    throw e if e
    unless acts?.length
      return logger.debug 'No acts found'
    logger.debug acts
    async.each acts, (act, done) ->
      ComLaw.downloadActFiles act.ComlawId, (e, newFile) =>
        act.output =
          path: newFile
        done()
    , (e) ->
      throw e if e
      logger.info 'Successfully finished downloading act series and files'
      logger.info acts
      makeGitRepoFromActs acts.reverse(), ->
        logger.info 'Finished!'

#main()
#makeGitRepoFromActs fixtures
