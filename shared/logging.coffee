# Vendor.
_ = require 'underscore'
path = require 'path'
stackTrace = require 'stack-trace'
require 'colors'

# @param pattern - A number for a pattern preset or a string containing the
#   actual pattern string.
module.exports = (opts = {}) ->
  _.defaults opts,
    pattern: null
    levels: {}
    globalLogLevel: 'TRACE'
  pattern = parsePattern opts.pattern
  onelog = require 'onelog'
  log4js = require 'log4js'
  onelog.use onelog.Log4js
  log4js.setGlobalLogLevel opts.globalLogLevel
  log4js.configure
    appenders: [
      {
        type: 'logLevelFilter'
        #category: []
        level: 'TRACE'
        appender:
          type: 'console'
          layout:
            type: 'pattern'
            pattern: pattern
            tokens:
              filename: getCallerFile
              level: level
      }
    ]
    levels: opts.levels


# Helpers
# -------

parsePattern = (pattern) ->
  unless pattern?
      patterns[4]
    else
      if pattern.preset? then patterns[pattern.preset] else pattern.pattern

# Returns to debug level in lowercase.
level = ->
  args = level.caller.arguments
  args[0].level.levelStr.toLowerCase()

# Gets the file path and line number relative to process.cwd().
#
# e.g.
#     ./amendment.coffee#86
#
# @param n - how far up the stack trace to look for where the log method
#   was called from user code. You may need to adjust this to find the sweet
#   spot.
getCallerFile = (n = 8) ->
  frame = stackTrace.get()[n]
  file = path.relative process.cwd(), frame.getFileName()
  dir = path.dirname file
  ext = path.extname file
  base = path.basename file, ext
  line = frame.getLineNumber()
  #method = frame.getFunctionName()
  "#{dir}/#{base.underline}#{ext}##{line}"

patterns =
  # TRACE Amendment - This is a message.
  1: "%[%p%] #{"%c".underline.grey} - %m"
  # TRACE Amendment (./amendment.coffee#86) - This is a message.
  2: "%[%p%] #{"%c".underline} (#{"%x{filename}"}) - %m"
  # DEBUG ./amendment.coffee#91 - This is a message.
  3: "%[%5p%] #{"%x{filename}".grey} - %m"
  # debug - This is a message.
  4: "%[%x{level}%] - %m"

# This prevents the correct level color being shown.
# We use the level token instead, which allows us to use our own colors.
makeLevelsLowerCase = (log4js) ->
  #Make levels lowercase.
  for k,v of log4js.levels
    if v.levelStr? then v.levelStr = v.levelStr.toLowerCase()
