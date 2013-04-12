util = require './util'
_ = require 'underscore'

# @method #filter ($, opts)
#   When defining a custom filter for processing an HTML element this is the
#   function signature that you must implement.
#
#   @this [Object] the current Cheerio element
#   @param [Function] $ a Cheerio object
#   @param [Object] opts the hash from the mappings file for the current element class name. If you need to pass additional options to your filter you should add keys to this hash in the mappings file.
class @CustomFilters

  @clearEmptyBoldTag: ($) ->
    $(@).find('b').each ->
      unless $(@).text().trim().length
        $(@).remove()

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
    # Remove dots and page numbering.
    # TODO: Brittle.
    spans = $(@).find('span')
    _.each _.last(spans, 2), (span) ->
      $(span).remove()

    # Replace all dots except first after section numbers with en spaces.
    html = $(@).html()
    i = 0
    html = html.replace /(\.)/g, ->
      if i++ is 0 then '.' else util.nonBreakingSpace

    $(@).html html

  # Add links to sections.
  @tocLinkify: ($) ->
    # We need to match sections which have a dash in the middle.
    # The dash can occasionally be a wierd dash. So we just match everything
    # up to the dot.
    # TODO: WARNING: If there are no dots this will break. If there are dots in the
    # section numbers - this will break.
    regex = /^([\w\W]*)(?=\.)/g
    section = $(@).text().match(regex)?[0]
    linkified = "<a href='##{section}'>#{section}</a>"
    $(@).html $(@).html().replace regex, linkified

  @tocHeading: ($) ->

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
