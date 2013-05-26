# For adding things like members, electorates, etc. before we scrape
# the hansard.

# OpenAustralia schema.
# https://github.com/sabman/OpenAustralia-REST-API/blob/master/schema.sql

# Vendor.
path = require 'path'
errTo = require 'errto'
inspect = require('eyes').inspector {maxLength: 5000}
_ = require 'underscore'
csv = require 'csv'
yacsv = require 'ya-csv'

# Libs.
{parseString} = require 'xml2js'
myutil = require '../util'

# Helpers.
root = (p) -> path.join 'data.openaustralia.org/members', p
csvRoot = (p) -> path.join 'data', p

# CSV reading.
readCSV = (p, done) ->
  p = myutil.fixturePath csvRoot p + '.csv'
  csv().from.path(p)
  .to (rows, count) ->
    done null, rows
  , columns: true
  .transform (row, id) ->
    console.log row, id
    # Skip comments.
    return null if row.charAt(0) is '#'
    return row

readYaCSV = (p, done) ->
  arr = []
  p = myutil.fixturePath csvRoot p + '.csv'
  reader = yacsv.createCsvFileReader p, {comment: '#', columnsFromHeader: true}
  reader.addListener 'data', (data) ->
    return null if data['person count'] is ''
    arr.push data
  reader.addListener 'end', -> done null, arr

pad = (num, size) ->
  s = num + ""
  s = "0" + s while s.length < size
  return s

# ---

Model = require('./model')()

class @OAXML

  constructor: ->
    @memberModelsByOAID = {}
    @memberModelsByPersonOAID = {}
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

    # Apply middle-names, aphId, etc.
    await @updateFromCSV @noErr defer()
    await @postCodes @noErr defer()
    done()

  postCodes: (done) =>
    await readYaCSV 'postcodes', @noErr defer postcodes
    for p in postcodes
      await Model.PostCodes.create
        postCode: p['Postcode']
        electorate: p['Electoral division name']
      .done @noErr defer done

  updateFromCSV: (done) =>
    await readYaCSV 'people', @noErr defer people
    # `person count` corresponds to the last chars in person's `oaId`
    # For each of these people we simply add the middlename.
    for p in people
      oaId = 'uk.org.publicwhip/person/1' + pad parseInt( p['person count'] ), 4
      model = @personModelsByOAID[oaId]
      aphId = p['aph id']
      altName = p['alt name']
      parseInitials = (name) ->
        return unless name?
        _(name.split(' ')).initial().map( (s) -> s.charAt 0 ).join ''

      attrs =
        aphId: aphId
        fullName: p['name']
        initials: parseInitials p['name']
        altName: altName
        altInitials: parseInitials p['alt name']

      # Update person.
      model.updateAttributes(attrs).done @noErr defer()

      # Update member.
      member = @memberModelsByPersonOAID[oaId]
      member.updateAttributes(attrs).done @noErr defer()

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
      @memberModelsByPersonOAID[person.oaId] = member
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
