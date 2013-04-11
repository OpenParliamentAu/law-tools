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

String::removeLineBreaks = ->
  @replace /\r?\n|\r/g, ' '

String::replaceLineBreaks = ->
  @replace /\r?\n|\r/g, ' '

isAlphanumeric = (str) ->
  not str.match /^[a-z0-9]+$/i

# In the case of:
#
#     A<b><i>B</i></b> C
#
# When node is <i>B</i> (tag)
# node.prev is <b> (tag)
# node.next is C (text node)
#
# So when we want to find A, we must recurse up until the first non-empty tag.
findPreviousNonEmptyElement = ($, dir, node) ->
  prev = null
  curr = node
  el = null
  until el? or not curr?
    prev = curr
    curr = $(curr).parent()[0]
    if curr.prev?.data?.length > 0
      # Found previous element.
      el = curr.prev
    if curr.type is 'root'
      # Not found.
      curr = null
  return el

replaceTagName = ($, $el, tagName) ->
  newEl = $("<#{tagName}></#{tagName}>")
  _.each $el.attribs, (index) ->
    $(newEl).attr $el.attribs[index].name, $el.attribs[index].value
  newEl.html $el.html()
  $el.after(newEl).remove()

  # Post-processing.
  $newEl = $(newEl)

  # Headings and paragraphs only contain text on a single line.
  if tagName.toString().match(/p/)?
    $newEl.text $newEl.text().removeLineBreaks()

  $newEl

convertNonBreakingSpaceToEnSpace = (str) ->
  str.replace /&nbsp;/g, '\u2002'

convertRelativeUrlsToAbsolute = ($, rootUrl) ->
  #$('a').each (i, value) ->
  #  $(@).attr 'href', url.resolve rootUrl, value
  $('img').each (i, img) ->
    $(@).attr 'src', "#{rootUrl}/#{$(img).attr('src')}"

# Create a mapping of definitions to their stubs.
# We use this map to search our stemmed legislation for usages of definitions to linkify.
extractDefinitions = ($) ->
  defs = {}
  # Extract data before manipulating html.
  $('.Definition').each ->
    # Optionally add anchor tags to each term being defined.
    terms = $(@).find('b > i')
    el = this
    terms.each ->
      stemmedText = getStemFromTerm @text()
      defs[stemmedText] = getSlugFromTerm @text()
  defs

getStemFromTerm = (text) ->
  # Stem all words.
  _text = text.trim().toLowerCase()
  stemmedArray = natural.PorterStemmer.tokenizeAndStem(_text)
  stemmedText = stemmedArray.join ' '
  stemmedText

getSlugFromTerm = (text) ->
  stemmedText = getStemFromTerm text
  slug = stemmedText.replace(/\s+/g, '-').replace(/[^\w-]+/g, '')
  slug

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
      slug = getSlugFromTerm @text()
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
    @html = convertNonBreakingSpaceToEnSpace @html

  postprocessHTML: (html) =>

  convertToMarkdown: (html) =>
    $ = cheerio.load html

    if @opts.outputDebug
      md = ''
      $.root().children().each ->
        md += toMarkdown $(@).html()
        md += '\n'
      # Write html too for debug.
      fs.writeFileSync path.resolve('./test/out/out.html'), html
      fs.writeFileSync path.resolve('./test/out/out.md'), md

    if @opts.outputSplit
      _.each @opts.fileMappings, (classes, fileName) =>
        md = ''
        _.each (classes), (clazz) =>
          html = $(clazz).html()
          if html?
            md += toMarkdown html
            md += '\n'
        dest = "./test/split/#{fileName}.md"
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
    definitions = extractDefinitions $

    # make all urls absolute
    convertRelativeUrlsToAbsolute $, @opts.url

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
            $el = replaceTagName $, $el, v.tag

          # Pad contents with tabs.
          # TODO: Not sure about this.
          unless (not v.padding?)
            #spaceChar = '\u2003' # &emsp;
            spaceChar = '\u2002' # &ensp;
            padding = ''; padding += spaceChar for x in [1..v.padding]
            $el.prepend padding

    # TODO: Some of this may apply to other tags.
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
          nextNode = findPreviousNonEmptyElement $, dir, node
        if nextNode?.type is 'text'
          pos = if dir is 'next' then 0 else nextNode.data.length - 1
          nextChar = nextNode.data.charAt pos

          unless isAlphanumeric nextChar
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
          start = getArrayPositionOfStemFromIndex(stemmedDocArray, result.index)
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

getArrayPositionOfStemFromIndex = (stemmedDocArray, index) ->
  # Go through all elements of array letter by letter until we have
  # counted up to the index. Then return position.
  charCount = 0
  wordPosition = null
  for word, i in stemmedDocArray
    if charCount is index
      wordPosition = i
      break
    else
      charCount += word.length + 1 # + 1 is because of spaces
  return wordPosition

html = fs.readFileSync getFile(_2012)
mappings = require './styles-2012'
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

converter.getHtml (e) ->
  converter.run2 (e, html) ->
    throw e if e
    #console.log html
