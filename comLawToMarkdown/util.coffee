natural = require 'natural'
_ = require 'underscore'

root = exports

emSpace = '\u2003' # &emsp;
enSpace = '\u2002' # &ensp;
@nonBreakingSpace = enSpace

String::removeLineBreaks = ->
  @replace /\r?\n|\r/g, ' '

String::replaceLineBreaks = ->
  @replace /\r?\n|\r/g, ' '

@isAlphanumeric = (str) ->
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
# @param [string] stopAtTag stop looking when we come across this tag.
@findPrevOrNextNonEmptyElement = ($, dir, node, stopAtTag = 'p') ->
  prev = null
  curr = node
  el = null
  until el? or not curr?
    prev = curr
    curr = $(curr).parent()[0]
    if curr[dir]?.data?.length > 0
      # Found previous element.
      el = curr[dir]
    if curr.type is 'root' or curr.name is stopAtTag
      # Not found.
      curr = null
  return el

@closest = ($, node, tagName) ->
  curr = node
  while curr?
    curr = $(curr).parent()[0]
    if curr.type is 'root'
      curr = null
    else if curr.name is tagName
      return curr
  return null

# Return array of element's parents.
@parents = ($, node) ->
  curr = node
  parents = []
  while curr?
    curr = $(curr).parent()[0]
    if curr.type is 'root'
      curr = null
    else
      parents.push curr
  return parents

@replaceTagName = ($, $el, tagName) ->
  newEl = $("<#{tagName}></#{tagName}>")
  _.each $el.attribs, (index) ->
    $(newEl).attr $el.attribs[index].name, $el.attribs[index].value
  newEl.html $el.html()
  $el.after(newEl).remove()

  # Post-processing.
  $newEl = $(newEl)

  # Paragraphs only contain text on a single line.
  #if tagName.toString().match(/p/)?
  #  $newEl.text $newEl.text().removeLineBreaks()

  $newEl

@convertNonBreakingSpaceToEnSpace = (str) ->
  str.replace /&nbsp;/g, root.nonBreakingSpace

@convertRelativeUrlsToAbsolute = ($, rootUrl) ->
  #$('a').each (i, value) ->
  #  $(@).attr 'href', url.resolve rootUrl, value
  $('img').each (i, img) ->
    $(@).attr 'src', "#{rootUrl}/#{$(img).attr('src')}"

@getStemFromTerm = (text) ->
  # Stem all words.
  _text = text.trim().toLowerCase()
  stemmedArray = natural.PorterStemmer.tokenizeAndStem(_text)
  stemmedText = stemmedArray.join ' '
  stemmedText

@getSlugFromTerm = (text) ->
  stemmedText = exports.getStemFromTerm text
  slug = stemmedText.replace(/\s+/g, '-').replace(/[^\w-]+/g, '')
  slug

# Create a mapping of definitions to their stubs.
# We use this map to search our stemmed legislation for usages of definitions to linkify.
@extractDefinitions = ($) ->
  defs = {}
  # Extract data before manipulating html.
  $('.Definition').each ->
    # Optionally add anchor tags to each term being defined.
    terms = $(@).find('b > i')
    el = this
    terms.each ->
      stemmedText = root.getStemFromTerm @text()
      defs[stemmedText] = root.getSlugFromTerm @text()
  defs

@getArrayPositionOfStemFromIndex = (stemmedDocArray, index) ->
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
