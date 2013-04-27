class @Util

  @getUserHome: ->
    process.env.HOME or process.env.HOMEPATH or process.env.USERPROFILE
