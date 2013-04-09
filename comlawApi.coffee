# A scraper for http://www.comlaw.gov.au/

request = require 'request'
cheerio = require 'cheerio'
_ = require 'underscore'
querystring = require 'querystring'
url = require 'url'
async = require 'async'
fs = require 'fs'
path = require 'path'
mkdirp = require 'mkdirp'
extend = require 'xtend'

comlawRoot = 'http://www.comlaw.gov.au/'

marriageAct = 'C1961A00012'

# main
# ----

# For a pre-downloaded act series page (Marriage Act 1961)

getBillsForMarriageAct = ->

  page = new ActSeriesPage html: fs.readFileSync './fixtures/comlaw/marriage-act-series.html'
  page.scrape (e, acts) ->
    page = new BillDownloadPage
      html: fs.readFileSync './fixtures/comlaw/marriage-act-download.html'
      billId: 'C2011C00192'
    page.scrape ->
      console.log page.data

#getBillsForMarriageAct()

#ComLaw.downloadBillSeries marriageAct, {}, ->
#  console.log 'done'
