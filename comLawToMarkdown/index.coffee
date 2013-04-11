# This file is used to test html to markdown conversion.
# To run:
#     coffee test/htmlToMarkdown.coffee

# Logging.
onelog = require 'onelog'
log4js = require 'log4js'
onelog.use onelog.Log4js
logger = onelog.get()

path = require 'path'
fs = require 'fs'
mkdirp = require 'mkdirp'
cheerio = require 'cheerio'
_ = require 'underscore'
jsdom = require 'jsdom'
url = require 'url'
natural = require 'natural'

root = 'downloads/comlaw/html/'
_2012 = 'C2012C00837'
_2011 = 'C2011C00192'

{toMarkdown} = require '../lib/to-markdown'

jquery = ['http://code.jquery.com/jquery.js']

test = './out'

getFile = (file) ->
  path.resolve path.join root, file + '.html'

util = require './util'

# @method #filter ($, opts)
#   When defining a custom filter for processing an HTML element this is the
#   function signature that you must implement.
#
#   @this [Object] the current Cheerio element
#   @param [Function] $ a Cheerio object
#   @param [Object] opts the hash from the mappings file for the current element class name. If you need to pass additional options to your filter you should add keys to this hash in the mappings file.
class CustomFilters

  @tableOfAmend: ($) ->
    # Remove dots after section numbers.
    # These elements are in a table so dots are not neccessary.
    # .TableOfAmend also includes spans with inline styles. We must be careful
    # to only remove multiple dots or it will mess up the styles.
    html = $(@).html()
    html = html.replace /(\.){2,}/g, ''
    $(@).html html

  @trim: ($) ->
    $(@).text $(@).text().trim()

  @toc: ($) ->
    # Remove page numbering.
    $(@).find('span').each ->
      $(@).remove()

    # Replace all dots except first after section numbers with en spaces.
    html = $(@).html()
    i = 0
    html = html.replace /(\.)/g, ->
      if i++ is 0 then '.' else '\u2002'

    $(@).html html

  # Add links to sections.
  @tocLinkify: ($) ->
    regex = /^([\w]*)(?=\.)/g
    section = $(@).text().match(regex)?[0]
    linkified = "<a href='##{section}'>#{section}</a>"
    $(@).html $(@).html().replace regex, linkified

  @anchorSection: ($) ->
    section = $(@).text()
    $(@).replaceWith "<a id='#{section}'></a>#{section}"

  @actHead: ($) ->
    # Remove line breaks.
    $(@).html $(@).html().removeLineBreaks()

  @actHeadLink: ($) ->
    # Remove toc anchor tags from headings.
    anchor = $(@).find('a')?[0]
    if anchor?
      # Replace element with its inner html.
      $(anchor).replaceWith $(anchor).html()

  # Optionally add anchor tags to each term being defined.
  @definition: ($) ->
    terms = $(@).find('b > i')
    el = this
    terms.each ->
      slug = util.getSlugFromTerm @text()
      $(el).prepend "<a name='#{slug}'></a>"
      # NOTE: If we prepend to the <i> tag it gets removed by something so we
      # don't use the line below:
      #$(@).prepend "<a name='#{slug}'></a>"

class Converter

  constructor: (@html, @opts = {}, done) ->

  getHtml: (done) =>
    @html = @preprocessHTML @html
    if @opts.cheerio
      @$ = cheerio.load @html
      done()
    else
      jsdom.env @html, jquery, (e, window) =>
        return done e if e
        @$ = window.$
        done()

  preprocessHTML: =>
    # convert nbsp; to space
    @html = util.convertNonBreakingSpaceToEnSpace @html

  postprocessHTML: (html) =>

  convertToMarkdown: (html) =>
    $ = cheerio.load html

    if @opts.outputDebug
      md = ''
      $.root().children().each ->
        md += toMarkdown $(@).html()
        md += '\n'
      # Write html too for debug.
      dest = path.join @opts.debugOutputDir, 'out'
      fs.writeFileSync path.resolve(dest + '.html'), html
      fs.writeFileSync path.resolve(dest + '.md'), md

    if @opts.outputSplit
      _.each @opts.fileMappings, (classes, fileName) =>
        md = ''
        _.each (classes), (clazz) =>
          html = $(clazz).html()
          if html?
            md += toMarkdown html
            md += '\n'
        dest = path.join @opts.markdownSplitDest, "#{fileName}.md"
        mkdirp path.dirname dest
        fs.writeFileSync dest, md

  # To wrap an element in two tags in the `styles` map you can write:
  #
  #     {tag: 'h1 i'}
  #
  # This method processes that.
  #applyTags = ($, el, tagStr) ->
  #  tags = tagStr.split ' '
  #  for tag in tags
  #    replaceTagName $, el, tag

  run2: (done) =>
    $ = @$

    # PRE-PROCESSING
    # ---
    # Before we start modifying the DOM we extract info from it.
    definitions = util.extractDefinitions $

    # make all urls absolute
    util.convertRelativeUrlsToAbsolute $, @opts.url

    # change tags to markdown-safe tags
    # v - new tag information
    # k - html selector
    _.each @opts.mappings, (v, k) =>
      els = $(".#{k}")
      _.each els, (el) =>
        $el = $(el)
        if $el.length

          # Remove tag and contents.
          if _.isEmpty(v) or not v?.tag?
            $el.remove()

          # Run custom filters. Filters are applied in the order they are
          # in the mappings file.
          _.each v.filters, (fname) =>
            return if _.contains @opts.disableFilters, fname
            fn = CustomFilters[fname]
            unless fn?
              return done new Error "Filter '#{fname}' not implemented"
            fn.apply $el, [$, v]

          # Change tag names.
          unless (not v.tag?) or (v.tag is '')
            $el = util.replaceTagName $, $el, v.tag

          # Pad contents with tabs.
          # TODO: Not sure about this.
          unless (not v.padding?)
            #spaceChar = '\u2003' # &emsp;
            spaceChar = '\u2002' # &ensp;
            padding = ''; padding += spaceChar for x in [1..v.padding]
            $el.prepend padding

    $('i').each ->

      # Any <i> tag's text should all be on same line
      # NOTE: Consider new lines.
      $(@).text $(@).text().trim().replaceLineBreaks()

      # If text follows an <i> element we should make sure there is a space
      # after the <i> element, otherwise it won't render correctly.
      #
      # This seems to be an issue created by GFM.
      #
      # To fix bug:
      #
      #     <i>The Marriage Act 1961 </i>
      #
      # which renders to:
      #
      #     The _Marriage Act 1961_as shown
      #
      ensureSpaceBeforeOrAfterItalicTag = (dir, node) ->
        nextNode = node[dir]
        if dir is 'prev'
          nextNode = util.findPreviousNonEmptyElement $, dir, node
        if nextNode?.type is 'text'
          pos = if dir is 'next' then 0 else nextNode.data.length - 1
          nextChar = nextNode.data.charAt pos

          unless util.isAlphanumeric nextChar
            if nextChar isnt ' '
              if dir is 'next'
                nextNode.data = ' ' + nextNode.data
              else
                nextNode.data = nextNode.data + ' '

      ensureSpaceBeforeOrAfterItalicTag 'next', @[0]
      ensureSpaceBeforeOrAfterItalicTag 'prev', @[0]

    # Replace Microsoft Word horizontal lines.
    # Finding them is tricky!
    $('.MsoNormal').each ->
      if $(@).html().match(/^\s$/)?
        $(@).parent().replaceWith '<hr>'

    # to-markdown.js bug - Markdown-permitted tags within a table will get
    # converted to markdown but the table is inserted as inline html.
    # We want to make sure the tags stay as html.
    # HACK: We will change them to inline styles.
    $('table b').each ->
      $(@).replaceWith "<span style='font-weight: bold;'>#{$(@).html()}</span>"

    $('table i').each ->
      $(@).replaceWith "<span style='font-style: italic;'>#{$(@).html()}</span>"

    # Linkify definitions.
    if @opts.linkifyDefinitions

      tokenizer = new natural.WordTokenizer

      originalDocText = $.root().text()
      originalDocText = originalDocText.trim().toLowerCase()
      originalDocArray = tokenizer.tokenize(originalDocText)

      # Manually stem!
      stemmedDocArray = []
      for word, i in originalDocArray
        stemmedDocArray.push natural.PorterStemmer.stem word
      stemmedDocText = stemmedDocArray.join ' '

      #definitions = marriag: definitions['marriag'] # DEBUG
      _.each definitions, (slug, stemmed) ->
        # For each stemmed definition, we try and find it in our
        # stemmed document.
        regex = ///#{stemmed}///gi
        wordsInDefinition = stemmed.split(' ').length

        # Find all unstemmed versions of this stemmed phrase.
        # Hash to efficiently collect unstemmed versions.
        unstemmedVersions = {}
        while result = regex.exec stemmedDocText
          # When we find an occurence we find the original unstemmed version
          # by matching the position of the word in our stemmed doc and our
          # original doc.
          start = util.getArrayPositionOfStemFromIndex(stemmedDocArray, result.index)
          end = start + wordsInDefinition
          stemmedDefinition = stemmedDocArray.slice start, end
          unstemmedDefinition = originalDocArray.slice start, end
          unstemmedVersions[unstemmedDefinition.join(' ')] = true

        # With all unstemmed versions, we can now replace each one with a link.
        _.each unstemmedVersions, (v, def) ->
          regex = ///(^|\s)(#{def})(\s|$)///gi

          $('p').each ->
            html = $(@).html()
            $(@).html html.replace regex, ($0, $1, $2, $3) ->
              "#{$1}<a href='##{slug}'>#{$2}</a>#{$3}"

    # Undo anchor tag creation in tables.
    # This is part of the to-markdown.js bug mentioned earlier.
    $('table a').each ->
      $(@).removeAttr 'href'

    # Remove newlines in all headings.
    $(':header').each ->
      $(@).html $(@).html().removeLineBreaks()
      $(@).find 'span'

    # Remove empty <p>, unless it contains an image.
    $('p.MsoHeader').each ->
      unless $(@).text().trim().length or $(@).find('img').length
        $(@).remove()

    # Escape square brackets.
    html = $.root().html().replace /\[/g, '\\['

    md = @convertToMarkdown html
    done null, md


html = fs.readFileSync getFile(_2012)
mappings = require './styles/styles-2012'
fileMappings =
  '1-info': ['.Section1']
  '2-contents': ['.Section2']
  '3-act': ['.Section3', '.Section4']
  '4-notes': ['.Section5', '.Section6', '.Section7', '.Section8', '.Section9']

converter = new Converter html.toString(),
  cheerio: true
  url: "http://www.comlaw.gov.au/Details/#{_2012}/Html"
  #disableFilters: ['definition']
  mappings: mappings
  fileMappings: fileMappings
  outputSplit: true
  outputDebug: true
  linkifyDefinitions: true
  debugOutputDir: './comLawToMarkdown/out'
  markdownSplitDest: './comLawToMarkdown/split/'

converter.getHtml (e) ->
  converter.run2 (e, html) ->
    throw e if e
    #console.log html
