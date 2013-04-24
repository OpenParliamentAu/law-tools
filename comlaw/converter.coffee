logger = require('onelog').get 'Converter'

fs = require 'fs'
path = require 'path'
mkdirp = require 'mkdirp'

{toMarkdown} = require './to-markdown'

class @Converter

  # @param [Object] data - scraped act data
  # @param [String] dest - where to save Markdown file.
  @convertToMarkdown: (id, data, dest, done) ->
    console.log 'here'

    if data.html?
      CustomFileConverter.convertHTMLtoMarkdown data.html, dest, (e) ->
        return done e if e
        logger.debug "Converted HTML bill #{id} to", dest
        done null, dest

    else if data.rtf?
      CustomFileConverter.convertRTFtoMarkdown data.rtf, dest, (e) ->
         return done e if e
         logger.debug "Converted rtf bill #{id} to", dest
         done null, dest

    else
      done null, null

# This is a converter I have written to manually convert Word HTML.
class CustomFileConverter

  @convertHTMLtoMarkdown: (html, dest, done) =>
    out = toMarkdown html
    mkdirp.sync path.dirname dest
    fs.writeFileSync dest, out
    done()

  @convertRTFtoMarkdown: (html, dest, done) =>
    logger.error 'TODO'
    done()
