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
