{ActSeriesPage} = require '../actSeriesPage'

getActsMetadata = ->

  page = new ActSeriesPage url: "http://www.comlaw.gov.au/Series/C1961A00012"
  page.scrape (e) ->
    throw e if e
    console.log page.getData().acts

getActsMetadata()
