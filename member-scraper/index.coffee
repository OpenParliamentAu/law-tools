errTo = require 'errto'

{MemberPage} = require './memberPage'

class @Members

  @scrapeMember: (mpid, done) ->
    page = new MemberPage url: "http://www.aph.gov.au/Senators_and_Members/Parliamentarian?MPID=#{mpid}"
    await page.scrape errTo done, defer data
    done null, data
