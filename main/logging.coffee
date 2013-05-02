module.exports = ->
  require 'colors'
  onelog = require 'onelog'
  log4js = require 'log4js'
  onelog.use onelog.Log4js
  log4js.setGlobalLogLevel 'TRACE'
  log4js.configure
    appenders: [
      {
        type: 'logLevelFilter'
        category: ['Amender Test', 'Amendment', 'AmendmentParser', 'Amender', 'Amend']
        level: 'INFO'
        appender:
          type: 'console'
          layout:
            type: 'pattern'
            pattern: "%[%p%] %c - %m"
      }
    ]
    levels:
      'Amender': 'OFF'
      'Amender': 'DEBUG'
