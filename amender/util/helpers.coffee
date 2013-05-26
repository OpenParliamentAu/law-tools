cheerio = require 'cheerio'
_ = require 'underscore'
logger = require('onelog').get()

# Get all elements up until an element with the same class name is
# found or end of siblings.
cheerio::getElementsUntilClass = (className, untilClasses) ->
  #untilClasses = getClassNamesAboveUnit className
  curr = @
  prev = null
  els = []
  while curr? and not _.isEmpty curr
    prev = curr
    curr = curr.next()
    #end1 = _.any untilClasses, (i) -> curr.hasClass(className)
    end = curr.hasClass(className)
    unless curr.length and curr isnt prev and not end # and not end1
      curr = null
    else
      els.push curr
  logger.debug "Found #{els.length} elements before next #{className} or last sibling"
  els

# Get all elements up until an element with the same class name is
# found or end of siblings.
cheerio::nextUntil = (filter) ->
  el = @
  return [] unless el.length
  curr = el.next()
  els = []
  while curr?
    if curr.length and not curr.filter(filter).length
      els.push curr
    else
      break
    curr = curr.next()
  els

# Some units (such as section and subdivision) contain their number in a
# sub-element. This method does just that.
cheerio::findUnitFromInnerSelector = (innerSelector, unitNo, headingType) ->
  els = @
  els = els.filter ->
    headingNo = @find(innerSelector).text()
    headingNo = headingNo.replace(headingType, '').trim()
    headingNo is unitNo
  els[0]
