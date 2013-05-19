logger = require('onelog').get()

# Vendor
cheerio = require 'cheerio'
_ = require 'underscore'
xpath = require 'xpath'
dom = require('xmldom').DOMParser
inspect = require('eyes').inspector {maxLength: false}
{parseString} = require 'xml2js'

class @Parser

  @parse: (xml, done) ->

    finish = (arr) ->
      arr = [] unless arr?
      return done null, arr

    $ = cheerio.load xml, xmlMode: true

    # Find `major-heading` with text `BILLS`
    billsHeading = $("major-heading:contains('BILLS')")
    return finish() unless billsHeading.length

    # Get siblings until next `major-heading`.
    els = billsHeading.nextUntil 'major-heading'
    return finish() unless els.length

    # Get minor headings.
    minorHeadings = $(els).filterByTagName 'minor-heading'

    # Get divisions.
    _divisions = []
    minorHeadings.each ->
      [billTitle, stage] = extractBillTitleAndStage @

      # Get all elements for this minor-heading.
      els = @nextUntil 'minor-heading, major-heading'

      # Find divisions.
      divisions = $(els).filterByTagName 'division'
      return unless divisions.length

      for el in divisions
        await Parser.processDivision el, defer e, o
        return done e if e

        # Hansard
        # -------

        # Get elements leading up to this division, after the last division.
        hansardEls = $(el).prevUntil -> _.contains ['division', 'minor-heading', 'major-heading'], @[0].name
        hansardJSON = $(hansardEls).map ->
          o = {}
          for k, v of @attr()
            o[k] = v
          o.contents = @html()
          o

        # Save.
        o.hansardXML = _.map( hansardEls, (el) -> $.html(el) ).join '\n'
        o.hansardJSON = hansardJSON

        # ---

        o.billTitle = billTitle
        o.stage = stage
        _divisions.push o

    done null, _divisions

  @processDivision: (divisionEl, done) ->

      o = {}

      # Get division as json.
      await parseString divisionEl.toString(), {explicitArray: false}, defer e, json
      return done e if e

      o.meta = json.division.$
      o.divisioncount = json.division.divisioncount.$

      ayes = o.divisioncount.ayes
      noes = o.divisioncount.noes

      # Get Majority and Minority.
      isMajority = (vote) ->
        return null if ayes is noes
        if vote
          return ayes > noes
        else
          return ayes < noes

      getMajority = ->
        return Math.abs ayes - noes

      # Prepare member vote object.
      membervotes = []
      for list in json.division.memberlist
        membervotes = membervotes.concat _.map list.member, (vote) ->
          _vote = isFor vote.$.vote
          id: vote.$.id
          vote: _vote
          majority: isMajority _vote
          name: vote._
      o.membervotes = membervotes
      o.majority = getMajority()

      done null, o

#
# Example:
#
#     Maritime Powers Bill 2012, Maritime Powers (Consequential Amendments)
#     Bill 2012; In Committee
#
extractBillTitleAndStage = (heading) ->
  arr = heading.text().split(';')
  _.map arr, (x) -> x.trim().replace('\n', '')

# Get map of member -> vote
isFor = (vote) ->
  switch vote
    when 'aye' then true
    when 'no' then false
    when 'nay' then false
    else vote
