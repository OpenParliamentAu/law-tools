#
# make test arg='test/amend.coffee'
#
require('../logging')()
logger = require('onelog').get()

path = require 'path'
wrench = require 'wrench'

{AmendRunner} = require '../amend'
{Git} = require 'git-tools'
{ComLaw} = require 'comlaw-scraper'
{Util} = require 'op-util'


workDir = path.join Util.getUserHome(), 'tmp/openparl/amend-runner/'

setupMasterRepo = (seriesComLawId, done) ->
  repoPath = path.join workDir, 'masterRepo'

  wrench.rmdirSyncRecursive repoPath

  await ComLaw.downloadActSeriesAndConvertToMarkdown seriesComLawId, workDir,
    first: 2
  , defer e, acts
  return done e if e

  await Git.makeGitRepo repoPath, defer e, repo
  return done e if e

  # Organize acts by:
  #   <lowercased-first-letter-of-act-name>/<cleaned-act-name>
  principalActName = Git.getPrincipalActName acts
  folderName = principalActName.charAt(0).toLowerCase()
  subdir = path.join folderName, principalActName

  await Git.addActsToGitRepo repo, acts.reverse(),
    version: 'test'
    subdir: subdir
  , defer e
  return done e if e
  logger.info 'Successfully updated repo at:', repoPath

  done null, repo, repoPath

describe 'Amend Runner', ->

  before ->

  # A lot of code comes from `main/single.coffee` for future refactoring.
  it 'Marriage Equality Amendment Act 2013', (done) ->

    # Marriage Equality Amendment Bill 2013
    seriesComLawId = 'C1961A00012'
    amendmentBillId = 's905'

    await setupMasterRepo seriesComLawId, defer e, repo, repoPath

    # Get acts.
    await AmendRunner.amend amendmentBillId, defer e, acts
    return done e if e

    # TODO: Checkout master first!
    # Create branch.
    await repo.create_branch amendmentBillId, defer e
    return done e if e

    await repo.checkout amendmentBillId, defer e
    return done e if e

    # Commit changes.
    await Git.addAmendedActsToGitRepo {}, repo, acts, {subdir: true}, defer e
    return done e if e

    done()
