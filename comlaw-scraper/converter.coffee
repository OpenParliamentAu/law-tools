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

    logger.start 'convert'
    if data.html?
      await CustomFileConverter.convertHTMLtoMarkdown id, data.html, dest, defer e, compilerInfo
      return done e if e
      t = logger.stop 'convert'
      logger.debug "Converted HTML bill #{id} to #{dest} (#{t}ms)"
      done null, dest, compilerInfo

    else if data.rtf?
      await CustomFileConverter.convertRTFtoText id, data.rtf, dest, defer e, compilerInfo
      return done e if e
      t = logger.stop 'convert'
      logger.debug "Converted rtf bill #{id} to #{dest} (#{t}ms)"
      done null, dest, compilerInfo

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

    await converter.getHtml defer e
    return done e if e

    await converter.convert defer e, md
    return done e if e

    mkdirp.sync path.dirname dest
    fs.writeFileSync dest, md
    done null, converter.getCompilerInfo()

  @convertRTFtoText: (id, rtf, dest, done) =>
    src = path.join workDir, '~data.rtf'
    mkdirp.sync path.dirname src
    fs.writeFileSync src, rtf
    cmd = "textutil -convert txt #{src} -output #{dest}"
    await exec cmd, defer e, stdout, stderr
    return done e if e
    #logger.debug stdout, stderr
    done null,
      name: 'textutil rtf to text'
      cmd: cmd
      type: 'text'

  @convertRTFtoMarkdown: (id, rtf, dest, done) =>
    src = path.join workDir, '~data.rtf'
    mkdirp.sync path.dirname src
    fs.writeFileSync src, rtf
    cmd = "textutil -convert html #{src} -stdout" +
          " | pandoc -f html -t markdown -o #{dest}"
    await exec cmd, defer e, stdout, stderr
    return done e if e
    #logger.debug stdout, stderr
    done null,
      name: 'textutil rtf to html, pandoc html to text'
      cmd: cmd
      type: 'markdown'

class @FileConverter

  @convertFileToMarkdown: (src, dest, done) =>
    mkdirp.sync path.dirname dest
    cmd = "textutil -convert html #{src} -stdout" +
          " | pandoc -f html -t markdown -o #{dest}"
    await exec cmd, defer e, stdout, stderr
    return done e if e
    #logger.debug stdout, stderr
    done()

  @convertFileToText: (src, dest, done) =>
    mkdirp.sync path.dirname dest
    cmd = "docsplit text #{src} -o #{dest}"
    await exec cmd, defer e, stdout, stderr
    return done e if e
    #logger.debug stdout, stderr
    done()
