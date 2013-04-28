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
aboriginalAffairs = 'C2004A03898'
_act = aboriginalAffairs

# Choose how many acts you want to be in your repo.
noOfActsToIncludeInRepo = null


# Creates a master repo and adds the Marriage Act Series.
addActSeriesToMasterRepo = (comLawId, workDir, done) ->
  repoPath = path.join workDir, 'masterRepo'

  await ComLaw.downloadActSeriesAndConvertToMarkdown comLawId, workDir,
    first: noOfActsToIncludeInRepo
  , defer e, acts
  return done e if e
  await Git.makeGitRepo repoPath, defer e, repo
  return done e if e

  # Organize acts by:
  #   <lowercased-first-letter-of-act-name>/<cleaned-act-name>
  principalActName = Git.getPrincipalActName acts
  folderName = principalActName.charAt(0).toLowerCase()
  subdir = path.join folderName, principalActName

  await Git.addActsToGitRepo repo, acts,
    version: 'test'
    subdir: subdir
  , defer e
  return done e if e
  logger.info 'Successfully updated repo at:', repoPath


# Makes a repo from act series.
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

# Main
# ----

workDir = path.join Util.getUserHome(), 'tmp/makeRepoFromActSeries'
mkdirp.sync workDir

program.parse process.argv
example = program.args[0] or 'separate-repos'
logger.info 'Running example:', example
switch program.args[0]
  when 'separate-repos'
    await makeRepoFromActSeries _act, workDir, defer e
  when 'master-repo'
    await addActSeriesToMasterRepo _act, workDir, defer e
  else
    await makeRepoFromActSeries _act, workDir, defer e

throw e if e
