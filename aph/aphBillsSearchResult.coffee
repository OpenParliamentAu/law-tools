_ = require 'underscore'

{BasePage} = require 'shared'

# A single page of act series results.
#
# e.g. http://www.comlaw.gov.au/Series/C2004A00467
class @APHBillPage extends BasePage

  scraper: (done) =>
    $ = @$
    obj = {}

    # Meta
    # ----

    obj.meta = @extractDefinitionList '#main_0_content_0_pnlSpecs > dl.specs'

    # Progress
    # --------

    progress = []
    houses = $("h2:contains('Progress') + span > table")
    houses.each ->
      houseName = @find('th').text() or 'Other'
      @find('tbody > tr').each ->
        progress.push
          house: houseName
          date: @find('td.date').text()
          event: @find('td:last-child').text()
    obj.progress = progress

    # Documents and transcripts
    # -------------------------

    # Text of bill
    obj.textOfBill = @extractDocsByHeading 'Text of bill'

    # Explanatory memoranda
    obj.explanatoryMemoranda = @extractDocsByHeading 'Explanatory memoranda'

    # Transcript of speeches
    obj.speechLinks = $("#main_0_content_0_speechLinks li > a").map ->
      title: @text()
      url: @attr('href')

    # Proposed amendments
    obj.proposedAmendments = @extractDocsByHeading 'Proposed amendments'

    # Schedule of amendments
    obj.scheduleOfAmendments = @extractDocsByHeading 'Schedule of amendments'

    # Committee Information
    obj.committeeInformation = @extractDocsByHeading 'Committee Information'

    # Bills Digest
    obj.billsDigest =
      link: $("#main_0_content_0_hlDigest").attr('href')
      pdf: $("#main_0_content_0_hlDigestPDF").attr('href')

    # Notes
    sel = "h3:contains('Notes') + ul.links > li"
    obj.notes = $(sel).map -> @text()

    done null, obj

  extractDocsByHeading: (heading) =>
    @extractDocs "h3:contains('#{heading}')"

  extractDocs: (selector) =>
    tables = nextUntil @$, selector, 'h3'
    docs = tables.map ->
      heading = @find('th').text() or null
      @find('tbody > tr').map ->
        o = {}
        o.title = @find('ul.links a').text()
        o.link = @find('ul.links a').attr('href')
        o.heading = heading if heading?
        o.docs = {}
        @find('td.format > a').each ->
          o.docs[@attr('title')] = @attr('href')
        o
    _.flatten docs


# Get all elements up until an element with the same class name is
# found or end of siblings.
nextUntil = ($, startEl, filter) ->
  el = $(startEl)
  return [] unless el.length
  curr = el.next()
  els = []
  while curr?
    if curr? and curr.length and not $(curr).filter(filter).length
      els.push curr
    else
      break
    curr = curr.next()
  $ els
