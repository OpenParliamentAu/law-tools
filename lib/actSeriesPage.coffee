# Libs.
{BasePage} = require './basePage'

class @ActSeriesPage extends BasePage

  scraper: (done) =>
    acts = @extractActs()
    done null, acts

  extractActs: =>
    actSeriesTableId = '#ctl00_MainContent_SeriesCompilations_RadGrid1_ctl00'
    acts = @extractTable actSeriesTableId
    {acts}
