path = require 'path'

class @Util

  @getUserHome: ->
    process.env.HOME or process.env.HOMEPATH or process.env.USERPROFILE

  @getTempDir: ->
    path.join Util.getUserHome(), 'tmp/op'
