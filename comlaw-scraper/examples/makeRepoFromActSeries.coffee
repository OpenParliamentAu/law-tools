logger = require('onelog').get 'Examples'

mkdirp = require 'mkdirp'
path = require 'path'
async = require 'async'
_ = require 'underscore'

{ComLaw} = require '..'
{Git} = require '../git'

marriageAct = 'C1961A00012'
marriageAct = 'C2004A00467'

getUserHome = -> process.env.HOME or process.env.HOMEPATH or process.env.USERPROFILE

# Makes a repo from the Marriage Act 1961 series.
makeRepoFromActSeries = (comLawId, workDir, done) ->
  repoDir = path.join workDir, 'repo'

  ComLaw.downloadActSeriesAndConvertToMarkdown comLawId, workDir,
    # DEBUG: Choose how many acts you want to be in your repo.
    first: 20
  , (e, acts) ->
    return done e if e
    Git.makeGitRepoFromActs acts.reverse(), {workDir: repoDir}, (e) ->
      return done e if e
      logger.info 'Finished!'

workDir = path.join getUserHome(), 'tmp/makeRepoFromActSeries'
mkdirp.sync workDir
makeRepoFromActSeries marriageAct, workDir, (e) ->
  throw e if e
