logger = require('onelog').get 'Examples'

mkdirp = require 'mkdirp'
path = require 'path'
async = require 'async'
_ = require 'underscore'

{ComLaw} = require '../comlaw'
{Git} = require '../git'

marriageAct = 'C1961A00012'

getUserHome = ->
  process.env.HOME or process.env.HOMEPATH or process.env.USERPROFILE

# Makes a repo from the Marriage Act 1961 series.
makeRepoFromActSeries = (workDir, done) ->
  repoDir = path.join workDir, 'repo'
  downloadedFilesDir = path.join workDir, 'files'
  markdownDir = path.join workDir, 'md'

  ComLaw.actSeries marriageAct, (e, acts) ->
    throw e if e
    unless acts?.length then return logger.debug 'No acts found'
    # DEBUG: Choose how many acts you want to listen to.
    acts = _.first acts, 2
    async.eachSeries acts, (actData, cb) ->
      ComLaw.downloadAct actData.ComlawId,
        downloadDir: downloadedFilesDir
      , (e, act) ->
        return cb e if e
        markdownDest = path.join markdownDir, actData.ComlawId + '.md'
        ComLaw.convertToMarkdown actData.ComlawId, act, markdownDest, (e) ->
          return cb e if e
          # Attach the generated Markdown file to the act.
          actData.masterFile = markdownDest
          cb()

    , (e) ->
      return done e if e
      logger.info 'Successfully finished downloading act series and files'
      logger.info acts
      Git.makeGitRepoFromActs acts.reverse(),
        workDir: repoDir
      , (e) ->
        return done e if e
        logger.info 'Finished!'

workDir = path.join getUserHome(), 'tmp/makeRepoFromActSeries'
mkdirp.sync workDir
makeRepoFromActSeries workDir, (e) ->
  throw e if e
