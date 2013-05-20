_ = require 'underscore'
temp = require 'temp'
errTo = require 'errto'
request = require 'request'
fs = require 'fs'

{BasePage} = require 'shared'

class @MemberPage extends BasePage

  scraper: (done) =>

    data =
      name: @$('h1').text()

    defs = @extractDefinitionList '.col-half > dl'
    _.extend data, defs

    get = (heading) =>
      if (el = @$ "h3:contains('#{heading}')").length
        @$.html el.next()
    # TODO: There are a few more sections I missed out.
    data.parlimentaryService = get 'Parlimentary service'
    data.committeeService = get 'Committee service'
    data.parliamentaryPartyPositions = get 'Parliamentary party positions'
    data.partyPositions = get 'Party positions'
    data.personal = get 'Personal'
    # TODO
    data.qualifications = get 'Qualifications and occipation before entering Federal Parliament'
    data.electorate = get 'Electorate'

    # Image.
    src = @$('#member-summary > p.thumbnail > img').attr 'src'
    dest = temp.path suffix: '.jpg'
    await @downloadFile dest, src, errTo done, defer()
    data.imagePath = dest

    done null, data

  downloadFile: (dest, url, done) =>
    request(url).pipe(fs.createWriteStream dest)
      .on 'error', (e) ->
        done new Error e
      .on 'close', ->
        console.log 'Close event fired'
        done()
      .on 'end', ->
        console.log 'Finished'
        done()
