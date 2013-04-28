logger = require('onelog').get 'Git'

wrench = require 'wrench'
_ = require 'underscore'
fs = require 'fs'
git = require 'gift'
path = require 'path'
mkdirp = require 'mkdirp'
async = require 'async'

class @Git

  # Ensure git repo exists.
  @makeGitRepo: (repoPath, done) ->
    mkdirp.sync repoPath
    await git.init repoPath, defer e, repo
    return done e if e
    done null, repo

  # Add acts to git repo.
  @addActsToGitRepo: (repo, acts, opts, done) ->

    # For each act we will copy the file into the repo,
    # and make a commit.
    async.eachSeries acts, (act, cb) ->

      # Copy file.
      return cb('No master file found') unless act.masterFile?
      src = act.masterFile
      # Use subdir.
      if opts.subdir?
        dest = path.join repo.path, opts.subdir, 'index.md'
      else
        dest = path.join repo.path, 'index.md'
      mkdirp.sync path.dirname dest
      fs.createReadStream(src).pipe fs.createWriteStream(dest)

      # Make commit.
      latestAmendment = act['Incorporating Amendments Up To']
      subject = unless latestAmendment is 'No records to display.'
        #"Incorporating amendments up to #{latestAmendment}"
        "#{latestAmendment} -> #{act.Title}"
      else
        "Current act as of #{act['Date Prepared']}"

      msg = """#{subject}

        Comlaw Id: #{act.ComlawId}
        Date Prepared: #{act['Date Prepared']}
        Comlaw Consolidated Act Link: #{act['Title Link'] or 'N/A'}
        Comlaw Amendment Link: #{act['Incorporating Amendments Up To Link'] or 'N/A'}

        Markdown automatically generated by v#{opts.version}"""
      repo.add path.resolve(dest), (e) ->
        return cb e if e
        repo.commit msg, {}, (e) ->
          if e
            logger.error "Commit failed! Perhaps there is nothing to commit?"
            return cb e if e
          logger.debug "Committed", msg
          cb()

    , (e) ->
      return done e if e
      done()

  @getPrincipalActName: (acts) ->
    # TODO: Brittle.
    parseActTitle = (title) ->
      a = (/(.*)/g.exec title)[0]
      a.replace /[ ]/g, '-'

    principalAct = acts[0]
    principalActTitle = parseActTitle principalAct.Title
    principalActTitle = principalActTitle.replace /[^a-zA-Z0-9_\-\.]/g, '-'

  # Creates a repo for an act.
  #
  # @param [Object] acts - Must be sorted from earliest to latest.
  @makeGitRepoFromActs: (acts, opts, done) ->
    unless done? then done = opts; opts = {}
    _.defaults opts,
      # Working directory. Repo dir will be created inside this dir.
      workDir: path.join __dirname, 'tmp'
      version: 'unknown'

    # Create directory which will contain repo.
    # We name the dir after the title of the principal act.
    # The dir is overidden if it exists.
    principalActTitle = Git.getPrincipalActName acts
    repoPath = path.join opts.workDir, principalActTitle
    wrench.rmdirSyncRecursive repoPath, true
    mkdirp.sync repoPath
    # ---

    await Git.makeGitRepo repoPath, defer e, repo
    return done e if e
    await Git.addActsToGitRepo repo, acts, opts, defer e
    return done e if e
    logger.info 'Successfully created repo at:', repoPath
