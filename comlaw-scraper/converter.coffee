logger = require('onelog').get 'Converter'

fs = require 'fs'
path = require 'path'
mkdirp = require 'mkdirp'
_ = require 'underscore'
{exec} = require 'child_process'

root = @

#{toMarkdown} = require 'to-markdown'
{Converter} = require 'comlaw-to-markdown'
{Util} = require 'op-util'

workDir = path.join Util.getUserHome(), 'tmp/comlaw-converter'

class @Converter

  # @param [Object] data - scraped act data
  # @param [String] dest - where to save Markdown file.
  @convertToMarkdown: (id, data, dest, done) ->

    # TODO: Pre-1996 should not be rendered as Markdown.

    if data.html?
      CustomFileConverter.convertHTMLtoMarkdown id, data.html, dest, (e) ->
        return done e if e
        logger.debug "Converted HTML bill #{id} to", dest
        done null, dest

    else if data.rtf?
      CustomFileConverter.convertRTFtoText id, data.rtf, dest, (e) ->
         return done e if e
         logger.debug "Converted rtf bill #{id} to", dest
         done null, dest

    else
      done null, null

# This is a converter I have written to manually convert Word HTML and RTF.
class CustomFileConverter

  @convertHTMLtoMarkdown: (id, html, dest, done) =>
    opts =
      fileName: id
      url: "http://www.comlaw.gov.au/Details/#{id}/Html"
      outputSplit: false
      outputDebug: false
      justMd: true
      cleanTables: true
    converter = new Converter html, opts
    converter.getHtml (e) ->
      return done e if e
      converter.convert (e, md) ->
        return done e if e
        mkdirp.sync path.dirname dest
        fs.writeFileSync dest, md
        done()

  @convertRTFtoText: (id, rtf, dest, done) =>
    src = path.join workDir, '~data.rtf'
    mkdirp.sync path.dirname src
    fs.writeFileSync src, rtf
    cmd = "textutil -convert txt #{src} -output #{dest}"
    child = exec cmd, (e, stdout, stderr) ->
      return done e if e
      #logger.debug stdout, stderr
      done()

  @convertRTFtoMarkdown: (id, rtf, dest, done) =>
    src = path.join workDir, '~data.rtf'
    mkdirp.sync path.dirname src
    fs.writeFileSync src, rtf
    cmd = "textutil -convert html #{src} -stdout" +
          " | pandoc -f html -t markdown -o #{dest}"
    child = exec cmd, (e, stdout, stderr) ->
      return done e if e
      #logger.debug stdout, stderr
      done()

class @FileConverter

  @convertFileToMarkdown: (src, dest, done) =>
    mkdirp.sync path.dirname dest
    cmd = "textutil -convert html #{src} -stdout" +
          " | pandoc -f html -t markdown -o #{dest}"
    child = exec cmd, (e, stdout, stderr) ->
      return done e if e
      #logger.debug stdout, stderr
      done()

  @convertFileToText: (src, dest, done) =>
    mkdirp.sync path.dirname dest
    cmd = "docsplit text #{src} -o #{dest}"
    child = exec cmd, (e, stdout, stderr) ->
      return done e if e
      #logger.debug stdout, stderr
      done()

