cheerio = require 'cheerio'
_ = require 'underscore'

_.extend cheerio::,
  prevUntil: (filter) ->
    el = this
    return [] unless el.length
    curr = el.prev()
    els = []
    while curr?
      if curr.length and not $(curr).filter(filter).length
        els.push curr
      else
        break
      curr = curr.prev()
    els

_.mixin
  takeWhile: (list, callback, context) ->
    xs = []
    _.any list, (item, index, list) ->
      res = callback.call(context, item, index, list)
      if res
        xs.push item
        false
      else
        true
    xs
