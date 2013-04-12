path = require 'path'
fs = require 'fs'

root = @
@curdir = (file) -> path.join __dirname, file
