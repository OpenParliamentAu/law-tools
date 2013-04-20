# Microsoft Word HTML to Markdown Converter

# Logging.
onelog = require 'onelog'
log4js = require 'log4js'
onelog.use onelog.Log4js

logger = onelog.get 'converter'
defLogger = onelog.get 'definitions'
logger.setLevel 'DEBUG'
#logger.setLevel 'TRACE'
defLogger.setLevel 'WARN'

# Vendor.
path = require 'path'
fs = require 'fs'
mkdirp = require 'mkdirp'
cheerio = require 'cheerio'
_ = require 'underscore'
jsdom = require 'jsdom'
url = require 'url'
natural = require 'natural'

# Libs.
{toMarkdown} = require './lib/to-markdown/to-markdown'
{CustomFilters} = require './filters'
util = require './util'

# Constants.
jquery = 'http://code.jquery.com/jquery.js'

class @Converter

  constructor: (@html, @opts = {}) ->
    _.defaults @opts,
      root: null
      # Use this when you have multiple sections in the document.
      convertEachRootTagSeparately: true
      cheerio: true
      outputSplit: true
      outputDebug: true
      linkifyDefinitions: false
      debugOutputDir: path.join __dirname, 'out/singleFile'
      markdownSplitDest: path.join __dirname, 'out/multipleFiles/'
      disabledFilters: []
      prettyTables: true
      # Should we convert absolute col widths to relative ones.
      relativeTableColWidths: true
      styleMappings: require path.join __dirname, 'styles/styles.coffee'

  getHtml: (done) =>
    @html = @preprocessHTML @html
    if @opts.cheerio
      @$ = cheerio.load @html
      if @opts.root?
        @html = @$(@opts.root).html()
        @$ = cheerio.load @html
      done()

    else
      jsdom.env @html, [jquery], (e, window) =>
        return done e if e
        @$ = window.$
        if @opts.root?
          @html = @$(@opts.root).html()
          @$ = cheerio.load @html
        done()

  preprocessHTML: =>
    @html = util.convertNonBreakingSpaceToEnSpace @html
    # Cleanup replacement char from `charset=windows-1252`.
    @html = @html.replace /�/g, util.nonBreakingSpace
    # Replace long dash with normal dash.
    @html = @html.replace /&#8212;/g, ' - '
    # Replace html dash with normal dash.
    @html = @html.replace /&#8209;/g, '-'
    #@html = @html.replace /\‑/g, '-'
    @html

  postprocessHTML: (html) =>

  convertToMarkdown: (html) =>
    $ = cheerio.load html

    if @opts.justMd
      md = ''
      $.root().children().each ->
        md += toMarkdown $(@).html()
        md += '\n'
      return md

    if @opts.outputSplit
      _.each @opts.fileMappings, (classes, fileName) =>
        md = ''
        _.each (classes), (clazz) =>
          _html = $(clazz).html()
          if _html?
            md += toMarkdown _html
            md += '\n'
        dest = path.join @opts.markdownSplitDest, "#{fileName}.md"
        mkdirp.sync path.dirname dest
        fs.writeFileSync dest, md
        logger.debug 'Wrote split md file', dest

    # During testing we return the entire md file.
    if @opts.outputDebug
      md = ''
      if @opts.convertEachRootTagSeparately
        $.root().children().each ->
          md += toMarkdown $(@).html()
          md += '\n'
      else
        md += toMarkdown $.root().html()

      base = path.basename @opts.fileName, path.extname @opts.fileName
      dest = path.join @opts.debugOutputDir, base
      mkdirp.sync path.dirname dest

      # Write to three files:
      htmlDest = path.resolve(dest + '.html')
      mdDest = path.resolve(dest + '.md')
      mdHtmlDest = path.resolve(dest + '.md.html')

      fs.writeFileSync htmlDest, html
      logger.debug "Wrote HTML to #{htmlDest}\n  open #{htmlDest}"
      fs.writeFileSync mdDest, md
      logger.debug "Wrote Markdown to #{mdDest}\n  lime #{htmlDest}"

      # Write rendered markdown html to file.
      marked = require 'marked'
      mdHtml = marked md
      # Inject github styles and header.
      css = fs.readFileSync path.join __dirname, 'github.css'
      html = """
       <!DOCTYPE HTML>
      <html>
      <head>
      <style type='text/css'>#{css}</style>
      <meta http-equiv="content-type" content="text/html;charset=utf-8">
      </head>
      <body style="margin: 20px; width: 600px">#{mdHtml}</body>
      </html>
      """
      # ---
      fs.writeFileSync mdHtmlDest, html
      logger.debug "Wrote rendered Markdown HTML to #{mdHtmlDest}\n  open #{mdHtmlDest}"

      return md


  # To wrap an element in two tags in the `styles` map you can write:
  #
  #     {tag: 'h1 i'}
  #
  # This method processes that.
  #applyTags = ($, el, tagStr) ->
  #  tags = tagStr.split ' '
  #  for tag in tags
  #    replaceTagName $, el, tag

  convert: (done) =>
    unless @html?
      done new Error 'Must call #getHtml first.'
    $ = @$

    logger.debug 'Converting', @opts.fileName

    # PRE-PROCESSING
    # ---
    # Before we start modifying the DOM we extract info from it.
    definitions = util.extractDefinitions $

    # make all urls absolute
    util.convertRelativeUrlsToAbsolute $, @opts.url

    # change tags to markdown-safe tags
    # v - new tag information
    # k - html selector
    _.each @opts.styleMappings, (v, k) =>
      logger.trace 'Processing mapping', k

      els = $(".#{k}")
      _.each els, (el) =>
        $el = $(el)
        if $el.length

          runFilters = (filters) =>
            # Filters are applied in the order they are in the mappings file.
            _.each filters, (fname) =>
              return if _.contains @opts.disabledFilters, fname
              fn = CustomFilters[fname]
              unless fn?
                return done new Error "Filter '#{fname}' not implemented"
              fn.apply $el, [$, v]

          # Only process tableFilters if we are inside a table.
          if util.isInsideTable($, el)
            runFilters v.tableFilters
            return

          # Remove tag and contents.
          if _.isEmpty(v) or not v?.tag?
            $el.remove()

          # Run custom filters.
          runFilters v.filters

          # Change tag names.
          unless (not v.tag?) or (v.tag is '')
            $el = util.replaceTagName $, $el, v.tag

          # Pad contents with tabs.
          # TODO: Not sure about this.
          unless (not v.padding?)
            padding = ''; padding += util.nonBreakingSpace for x in [1..v.padding]
            $el.before padding

    logger.trace 'Processing <i></i>'
    $('i').each ->

      return if util.isInsideTable($, @)

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
      spaceLog = onelog.get 'ensureSpaceBeforeOrAfterTag'
      spaceLog.setLevel 'TRACE'
      spaceLog.suppress()
      ensureSpaceBeforeOrAfterTag = (dir, node, $el) ->
        log = (msg...) -> spaceLog.trace(msg...) if $(node).text() is 'prima facie'
        #nextNode = node[dir]
        nextNode = util.findPrevOrNextNonEmptyElement $, dir, node
        log nextNode.data
        if nextNode?.type is 'text'
          pos = if dir is 'next' then 0 else nextNode.data.length - 1
          nextChar = nextNode.data.charAt pos
          log nextChar
          unless util.isAlphanumeric nextChar
            log 'here'
            if nextChar isnt ' '
              if dir is 'next'
                nextNode.data = ' ' + nextNode.data
              else
                nextNode.data = nextNode.data + ' '
        log nextNode.data
        log '------------'

      ensureSpaceBeforeOrAfterTag 'next', @[0], @
      ensureSpaceBeforeOrAfterTag 'prev', @[0], @

    # Replace Microsoft Word horizontal lines.
    # Finding them is tricky!
    $('.MsoNormal').each ->
      if $(@).html().match(/^\s$/)?
        if $(@).parent?.type is 'root'
          $(@).parent().replaceWith '<hr/>'

    # to-markdown.js bug - Markdown-permitted tags within a table will get
    # converted to markdown but the table is inserted as inline html.
    # We want to make sure the tags stay as html.
    # HACK: We will change them to inline styles.
    # TODO: DISABLED
    if (false)
      $('table b').each ->
        $(@).replaceWith "<span style='font-weight: bold;'>#{$(@).html()}</span>"

      $('table i').each ->
        $(@).replaceWith "<span style='font-style: italic;'>#{$(@).html()}</span>"

      $('table p').each ->
        newEl = util.replaceTagName $, $(@), 'div'

    # Process asterisks.
    # Before processing definitions we must remove asterisks.
    # Asterisks are placed before words which have been defined.
    # TODO: Possible data loss - revisit.
    #   We are removing asterisks and relying on our own linkifying
    #   We are possibly losing information here. This should be revisited at
    #   some point.
    #   However, there is no way of telling how long the definition is from
    #   the asterisk, so our linkifying may be the only solution.
    els = $('span').filter ->
      if $(@).text() is '*'
        return true
    els.each ->
      $(@).after ' '

    # Linkify definitions.
    if @opts.linkifyDefinitions
      logger.trace 'Linkifying definitions'

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
        return unless stemmed.length
        logStr = "  Linked definition: #{stemmed}"
        defLogger.trace "Linking: ", stemmed, slug
        defLogger.startTimer logStr
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
        defLogger.startTimer '  Replace phase'
        _.each unstemmedVersions, (v, def) ->
          replaceFn = (html) ->
            regex = ///(^|\s)(#{def})(\s|$)///gi
            html.replace regex, ($0, $1, $2, $3) ->
              "#{$1}<a href='##{slug}'>#{$2}</a>#{$3}"
          # Use cheerio (slower).
          $('p').each ->
            html = $(@).html()
            $(@).html replaceFn html
          # Don't use cheerio (faster).
          #html = replaceFn $.root().html()
          #$ = cheerio.load html
        defLogger.stopTimer 'trace', '  Replace phase'

        defLogger.stopTimer 'trace', logStr
      defLogger.trace 'Finished linkifying all definitions'

    # Undo anchor tag creation in tables.
    # BUG: This is part of the to-markdown.js bug mentioned earlier.
    $('table a').each ->
      $(@).removeAttr 'href'

    # Remove newlines in all headings.
    $(':header').each ->
      $(@).html $(@).html().replaceLineBreaks()

    # Remove empty <p>, unless it contains an image.
    $('p.MsoHeader').each ->
      unless $(@).text().trim().length or $(@).find('img').length
        $(@).remove()

    # Unwrap elements.
    $('span').each ->
      # Unless surrounded by a table.
      unless util.isInsideTable($, @)
        $(@).replaceWith $(@).html()

    $('p').each ->
      unless util.isInsideTable($, @)
        $(@).replaceWith $(@).html().replaceLineBreaks()

    $('em').each -> $(@).html $(@).html().replaceLineBreaks()

    # Remove empty tags.
    $('i').each ->
      if $(@).text().trim().length is 0
        $(@).remove()

    # Remove a empty divs.
    $('div').each ->
      unless util.isInsideTable($, @)
        style = $(@).attr 'style'
        unless $(@).text().trim().length
          if style?.search('border-bottom') >= 0
            # A divider! Replace it with a proper one.
            $(@).replaceWith '<hr/>'
        else
          # There is text in this div. Could be a section box.
          if style?.search('border:solid') >= 0
            $(@).replaceWith '<hr/>' + $(@).html() + '<hr/>'

    # Don't allow two strong tags next to each other. Separate with a space.
    $('strong, b').each ->
      $(@).find('br').remove()
      $(@).html $(@).html().trim().replaceLineBreaks()
      unless $(@).text().trim().length
        $(@).remove()
      if $(@).next()[0].name is 'strong'
        $(@).after '\u2002'

    # Remove inline styles and class names from tables.
    if @opts.cleanTables

      #removeAllAttrs = (el) ->
      #  for name, val of el.attribs
      #    $(el).removeAttr name

      that = @
      $('table').each ->
        # NOTE: The following line won't work because I'm pretty sure Github
        # doesn't allow inline style tags.
        #$(@).before "<style type='text/css'>table td {vertical-align: top}</style>\n"
        $(@).removeAttr 'class'
        $(@).removeAttr 'cellspacing'
        $(@).removeAttr 'cellpadding'
        $(@).removeAttr 'style'
        $(@).removeAttr 'border'
        $(@).removeAttr 'width' # Not sure.
        table = @

        # Create colgroup to replace cell widths.
        colWidths = []
        $(table).find('tr').each (i, tr) ->
          # Row must not have colspans.
          colSpanTds = $(tr).find('td').filter -> $(@).attr('colspan')?
          unless colSpanTds.length
            # Row with no colspans.
            $(tr).find('td').each (i, td) ->
              colWidths.push $(td).attr 'width'
            return false # Breaks out of loop.
          # TODO: If row does have colspans, should we leave them in?

        if colWidths.length

          if that.opts.relativeTableColWidths
            sum = (arr) ->
              if arr.length > 0
                arr.reduce (x, y) ->
                  x + parseInt(y)
                , 0
              else 0

            totalColWidths = sum colWidths

            colWidths = _.map colWidths, (w) ->
              ((w / totalColWidths) * 100).toFixed(0) + '%'

          colgroup = (for width in colWidths then "  <col width='#{width}'/>").join '\n'
          table.prepend "\n\n<colgroup>\n#{colgroup}\n</colgroup>"

        # Remove styles and widths from trs and tds.
        $(@).find('tr, td').each ->
          $(@).removeAttr 'style'
          $(@).removeAttr 'valign'
          $(@).removeAttr 'width'

        # Pretty print html tables.
        if that.opts.prettyTables
          html = require 'html'
          data = $(@).html()
          prettyData = html.prettyPrint data,
            indent_size: 2
            unformatted: ['col', 'colgroup']
          $(@).html prettyData

      # Unwrap <p> tags.
      $('table p').each ->
        $(@).replaceWith $('<div></div>').html $(@).html().trim().replaceLineBreaks().removeMultipleWhiteSpace()

      $('table span').each ->
        $(@).replaceWith $(@).html()


    # --- Start html string modifications.

    html = $.root().html()

    # Escape square brackets.
    # Unless they are immediately followed by a opening tag.
    # TODO: This could be made a bit more robust.
    html = html.replace /\[(?!\<)/g, '\\['

    html = html.replace /&#8194;/g, util.nonBreakingSpace
    html = html.replace /&#10;/g, util.nonBreakingSpace

    # Convert all line-endings to unix.
    html = html.replace /\r/g, '\n'

    logger.trace 'Converting to Markdown'
    md = @convertToMarkdown html

    done null, md
