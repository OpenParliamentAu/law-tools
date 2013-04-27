onelog = require 'onelog'
log4js = require 'log4js'
onelog.use onelog.Log4js, methods: 'setLevel'
log4js.setGlobalLogLevel 'INFO'
logger = onelog.get()

mkdirp = require 'mkdirp'
path = require 'path'
async = require 'async'
_ = require 'underscore'
program = require 'commander'

{ComLaw} = require '..'
{Git} = require 'git-tools'
{Util} = require 'op-util'

marriageAct = 'C1961A00012'
aNewTaxSystemAct1999 = 'C2004A00467'
act = aNewTaxSystemAct1999

# Choose how many acts you want to be in your repo.
noOfActsToIncludeInRepo = 2

# Creates a master repo and adds the Marriage Act Series.
addActSeriesToMasterRepo = (comLawId, workDir, done) ->
  repoPath = path.join workDir, 'masterRepo'

  await ComLaw.downloadActSeriesAndConvertToMarkdown comLawId, workDir,
    first: noOfActsToIncludeInRepo
  , defer e, acts
  return done e if e
  await Git.makeGitRepo repoPath, defer e, repo
  return done e if e
  await Git.addActsToGitRepo repo, acts, {version: 'test'}, defer e
  return done e if e
  logger.info 'Successfully updated repo at:', repoPath

# Makes a repo from the Marriage Act 1961 series.
makeRepoFromActSeries = (comLawId, workDir, done) ->
  repoDir = path.join workDir, 'repos'

  await ComLaw.downloadActSeriesAndConvertToMarkdown comLawId, workDir,
    first: noOfActsToIncludeInRepo
  , defer e, acts
  return done e if e

  await Git.makeGitRepoFromActs acts.reverse(),
    workDir: repoDir
    version: ComLaw.getVersion()
  , defer e
  return done e if e
  logger.debug 'Finished creating repo!'


# Main
# ----

workDir = path.join Util.getUserHome(), 'tmp/makeRepoFromActSeries'
mkdirp.sync workDir

program.parse process.argv
example = program.args[0] or 'separate-repos'
logger.info 'Running example:', example
switch program.args[0]
  when 'separate-repos'
    await makeRepoFromActSeries act, workDir, defer e
  when 'master-repo'
    await addActSeriesToMasterRepo act, workDir, defer e
  else
    await makeRepoFromActSeries act, workDir, defer e
throw e if e
