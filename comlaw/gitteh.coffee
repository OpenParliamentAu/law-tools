gitteh.initRepository repoPath
gitteh.openRepository repoPath, (e, repo) ->
  throw e if e

  # for each act we will copy the file into the repo, and make a commit
  # TODO: Bills must be sorted from earliest to latest.
  async.each acts, (act, done) ->

    # Get HEAD ref.
    #headRef = repo.getReference 'HEAD'
    #headRef = headRef.resolve()
    #headCommit = repo.getCommit headRef.target
    #tree = repo.getTree headCommit.tree

    # Copy file.
    src = act.masterFile
    dest = path.join repoPath, path.basename(act.masterFile)
    fs.createReadStream(src).pipe fs.createWriteStream(dest)

    # Make commit.
    commit = repo.createCommit
      author: 'Parliament <admin@openparliament.com.au>'
      committer: 'Parliament <admin@openparliament.com.au>'
      id: 'something'
      message: "Bill Id: #{act.ComlawId}"
      tree: ''
    commit.save (r) ->
      console.log 'Commit success?', r
      done()

