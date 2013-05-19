cheerio = require 'cheerio'
_ = require 'underscore'
path = require 'path'
fs = require 'fs'

nextOrPrevUntil = (dir, filter) ->
  el = this
  return [] unless el.length
  curr = el[dir]()
  els = []
  while curr?
    if curr.length and not curr.filter(filter).length
      els.push curr
    else
      break
    curr = curr[dir]()
  els

_.extend cheerio::,
  prevUntil: (filter) -> nextOrPrevUntil.call @, 'prev', filter
  nextUntil: (filter) -> nextOrPrevUntil.call @, 'next', filter
  filterByTagName: (tagName) ->
    @filter -> @[0].name is tagName

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

dir = path.join process.env.OPENPARL_FIXTURES, 'voting-record'
@fixturePath = (p) -> path.join dir, p
@readFixture = (p) ->
  file = exports.fixturePath p
  fs.readFileSync file, 'utf8'
