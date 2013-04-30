onelog = require 'onelog'
log4js = require 'log4js'
onelog.use onelog.Log4js, methods: 'setLevel'
log4js.setGlobalLogLevel 'INFO'
logger = onelog.get()
log4js.configure
  appenders: [
    {
      # Log to console.
      type: 'console'
      layout:
        type: 'pattern'
        pattern: '%m'
    }
  ]

mkdirp = require 'mkdirp'
path = require 'path'
async = require 'async'
_ = require 'underscore'
program = require 'commander'

{ComLaw} = require 'comlaw-scraper'
{Git} = require 'git-tools'
{Util} = require 'op-util'
pjson = require '../package.json'

noOfActsToIncludeInRepo = null
workDir = path.join Util.getUserHome(), 'tmp/openparl-examples'

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
  repoDir = path.join workDir, 'seriesRepos'

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

@run = (comLawId, command) ->

  # Choose how many acts you want to be in your repo.
  noOfActsToIncludeInRepo = command.numberOfActs or null

  if command.debug
    log4js.setGlobalLogLevel 'DEBUG'

  mkdirp.sync workDir

  # Run example.
  if command.singleRepo?
    await makeRepoFromActSeries comLawId, workDir, defer e
  else
    await addActSeriesToMasterRepo comLawId, workDir, defer e
  throw e if e
