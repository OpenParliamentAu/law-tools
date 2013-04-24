logger = require('onelog').get 'Git'

wrench = require 'wrench'
_ = require 'underscore'
fs = require 'fs'
git = require 'gift'
path = require 'path'
mkdirp = require 'mkdirp'
async = require 'async'

# TODO: Brittle.
parseActTitle = (title) ->
  a = (/(.*)/g.exec title)[0]
  a.replace /[ ]/g, '-'

class @Git

  # Creates a repo for an act.
  #
  # @param [Object] acts - Must be sorted from earliest to latest.
  @makeGitRepoFromActs: (acts, opts, done) ->
    unless done? then done = opts; opts = {}
    _.defaults opts,
      # Working directory. Repo dir will be created inside this dir.
      workDir: path.join __dirname, 'tmp'

    # Create directory which will contain repo.
    # We name the dir after the title of the principal act.
    # The dir is overidden if it exists.
    principalAct = acts[0]
    principalActTitle = parseActTitle principalAct.Title
    repoPath = path.join opts.workDir, principalActTitle
    wrench.rmdirSyncRecursive repoPath, true
    mkdirp.sync repoPath
    # ---

    # Initialize repo.
    git.init repoPath, (e, repo) ->
      return done e if e

      # For each act we will copy the file into the repo,
      # and make a commit.
      async.eachSeries acts, (act, done) ->

        # Copy file.
        return done unless act.masterFile?
        src = act.masterFile
        dest = path.join repoPath, 'index.md'
        fs.createReadStream(src).pipe fs.createWriteStream(dest)

        # Make commit.
        latestAmendment = act['Incorporating Amendments Up To']
        subject = unless latestAmendment is 'No records to display.'
          "Incorporating amendments up to #{latestAmendment}"
        else
          "Current act as of #{act['Date Prepared']}"
        msg = """#{subject}

          Comlaw Id: #{act.ComlawId}
          Date Prepared: #{act['Date Prepared']}
          Comlaw Consolidated Act Link: #{act['Title Link'] or 'N/A'}
          Comlaw Amendment Link: #{act['Incorporating Amendments Up To Link'] or 'N/A'}

          Markdown automatically generated by OpenParliamentAu ComLaw Parser v0.0.1"""
        repo.add path.resolve(dest), (e) ->
          return done e if e
          repo.commit msg, {}, (e) ->
            logger.debug "Committed", msg
            return done e if e
            done()

      , (e) ->
        logger.info 'Successfully created repo at:', repoPath
        return done e if e
