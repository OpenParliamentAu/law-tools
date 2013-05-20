module.exports = ->
  onelog = require 'onelog'
  log4js = require 'log4js'
  onelog.use onelog.Log4js
  log4js.setGlobalLogLevel 'DEBUG'
  log4js.configure
    appenders: [
      {
        type: 'logLevelFilter'
        category: ['Amender Test', 'Amendment', 'AmendmentParser', 'Amender']
        level: 'INFO'
        appender:
          type: 'console'
          layout:
            type: 'pattern'
            pattern: "%[%p%] %c - %m"
      }
    ]
    levels:
      'Amender': 'DEBUG'
      'Amender': 'OFF'
