# For adding things like members, electorates, etc. before we scrape
# the hansard.

# OpenAustralia schema.
# https://github.com/sabman/OpenAustralia-REST-API/blob/master/schema.sql

# Vendor.
path = require 'path'
errTo = require 'errto'
inspect = require('eyes').inspector {maxLength: 5000}
_ = require 'underscore'

# Libs.
{parseString} = require 'xml2js'
myutil = require '../util'

# Helpers.
root = (p) -> path.join 'data.openaustralia.org/members/', p

Model = require('./model')()

class @OAXML

  constructor: ->
    @memberModelsByOAID = {}
    @personModelsByOAID = {}
    # For attaching a personId to a member and memberOffice.
    # Prepared when passing `people.xml`.
    @personModelsByOfficeOAID = {}

  toDb: (done) =>
    @noErr = errTo.bind null, done
    # NOTE: The ordering here is significant.
    await @people @noErr defer()
    await @constituencies @noErr defer()
    await @members 'representatives', @noErr defer()
    await @members 'senators', @noErr defer()
    await @memberOffices @noErr defer()
    done()

  # Returns xml file as json.
  parseStringSync: (file) ->
    xml = myutil.readFixture root "#{file}.xml"
    json = null
    parseString xml,
      explicitRoot: false
      explicitArray: false
    , (e, r) ->
      return json = new Error(e) if e
      json = r
    json

  constituencies: (autocb) =>
    json = @parseStringSync 'divisions'
    for d in json.division
      await Model.Constituency.create
        name: d.name.$.text
      .done @noErr defer()
    return

  memberOffices: (autocb) =>
    json = @parseStringSync 'ministers'
    for m in json.ministerofficegroup
      m = m.moffice.$
      await Model.MemberOffice.create
        toDate: m.todate
        fromDate: m.fromdate
        name: m.name
        position: m.position
        oaId: m.id
        # FK.
        memberId: @personModelsByOfficeOAID[m.matchid].id
      .done @noErr defer()
    return

  @parseReason: (reason) ->
    reason.replace(';', '').trim().replace(' ', '_')

  # TODO: We need to get their initials too because its the only way
  #   to unambigously match them from divisions.
  members: (house, autocb)  =>
    json = @parseStringSync house
    for m in json.member
      m = m.$

      # Party.
      await Model.Party.findOrCreate(name: m.party).done @noErr defer party

      person = @personModelsByOfficeOAID[m.id]
      await Model.Member.create
        firstName: m.firstname
        lastName: m.lastname
        constituency: m.division
        house: m.house
        enteredHouse: m.fromdate
        enteredReason: OAXML.parseReason m.fromwhy
        leftHouse: m.todate
        leftReason: OAXML.parseReason m.towhy
        title: m.title
        oaId: m.id
        # Denorm.
        party: m.party
        # FK.
        personId: person.id
        partyId: party.id
      .done @noErr defer member
      @memberModelsByOAID[m.id] = member
    return

  #
  # People
  # ------
  #

  people: (autocb) =>
    @person = {}

    @processPerson()
    @processPersonInfo 'websites'
    @processPersonInfo 'wikipedia-commons'
    @processPersonInfo 'wikipedia-lords'
    @processPersonInfo 'twitter'
    @processPersonInfo 'links-abc-qanda'

    for k, person of @person
      await Model.Person.findOrCreate {oaId: k},
        latestName: person.latestName
        oaId: person.oaId
        json: JSON.stringify person
      .done @noErr defer personModel

      @personModelsByOAID[person.oaId] = personModel
      for office in _.asArray person.offices
        @personModelsByOfficeOAID[office.$.id] = personModel

    return

  processPerson:  =>
    json = @parseStringSync 'people'
    for p in json.person
      @person[p.$.id] or= {}
      _.defaults @person[p.$.id],
        latestName: p.$.latestname
        oaId: p.$.id
        offices: p.office
    return

  processPersonInfo: (file, json) =>
    json = @parseStringSync file
    for p in json.personinfo
      @person[p.$.id] or= {}
      _.defaults @person[p.$.id], p.$
    return

  # ---

  # TODO
  #election: (autocb) =>
  #  json = @parseStringSync 'links-abc-election'
  #  #json.consinfo
  #  #abc_election_results_2007
  #  #abc_election_results_2010
  #  #canonical
