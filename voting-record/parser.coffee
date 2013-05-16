# Vendor
cheerio = require 'cheerio'
_ = require 'underscore'
xpath = require 'xpath'
dom = require('xmldom').DOMParser
inspect = require('eyes').inspector({maxLength: false})

class @Parser

  @parse: (xml, done) ->

    doc = new dom().parseFromString xml
    divs = []

    # Find `major-heading` with text BILLS
    nodes = xpath.select '//major-heading[contains(text(), "BILLS")][1]/following-sibling::*', doc
    return done(null, []) unless nodes.length
    # Get siblings until next `major-heading`.
    nodes = _.takeWhile nodes, (el) -> el.tagName isnt 'major-heading'
    #console.log _.pluck nodes, 'tagName'
    # Find divisions.
    divisions = _.filter nodes, (el) -> el.tagName is 'division'
    return done(null, []) unless divisions.length

    for division in divisions
      obj = {}

      # Get division info.
      await parseString division.toString(), {explicitArray: false}, defer e, json
      return done e if e
      obj.meta = json.division.$
      obj.divisioncount = json.division.divisioncount.$

      # ---
      # Get map of member -> vote
      isFor = (vote) ->
        switch vote
          when 'aye' then true
          when 'no' then false
          when 'nay' then false
          else vote

      ayes = obj.divisioncount.ayes
      noes = obj.divisioncount.noes

      # Get Majority and Minority
      isMajority = (vote) ->
        return null if ayes is noes
        if vote
          return ayes > noes
        else
          return ayes < noes

      getMajority = ->
        return Math.abs ayes - noes

      membervotes = []
      for list in json.division.memberlist
        membervotes = membervotes.concat _.map list.member, (vote) ->
          _vote = isFor vote.$.vote
          id: vote.$.id
          vote: _vote
          majority: isMajority _vote
          name: vote._
      obj.membervotes = membervotes
      # ---


      # Find nearest `minor-heading` which holds the title of the division.
      #console.log division.tagName

      title = xpath.select 'preceding-sibling::minor-heading[1]/text()', division
      str = title.toString()

      # Extract name.
      # e.g.
      #   Maritime Powers Bill 2012, Maritime Powers (Consequential Amendments)
      #   Bill 2012; In Committee
      str = str.split ';'
      obj.billTitle = str[0]
      obj.majority = getMajority()

      # Select text from title to division.
      titleEl = xpath.select 'preceding-sibling::minor-heading[1]', division
      nodes = _.takeWhile nodes, (el) -> el.tagName isnt 'division'
      obj.hansard = nodes.toString()

      #console.log inspect obj
      divs.push obj

    done null, divs
