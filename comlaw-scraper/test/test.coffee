marriageAct =
  seriesPath: './fixtures/comlaw/marriage-act-series.html'
  downloadPath: './fixtures/comlaw/marriage-act-download.html'
  billId: 'C2011C00192'

{ActSeriesPage} = require './actSeriesPage'
{BillDownloadPage} = require './billDownloadPage'

# For a pre-downloaded act series page (Marriage Act 1961)
getBillsForMarriageAct = ->

  page = new ActSeriesPage html: fs.readFileSync marriageAct.seriesPath
  page.scrape (e, acts) ->
    page = new BillDownloadPage
      html: fs.readFileSync marriageAct.downloadPath
      billId: marriageAct.billId
    page.scrape ->
      console.log page.data

#getBillsForMarriageAct()

#ComLaw.downloadBillSeries marriageAct, {}, ->
#  console.log 'done'
