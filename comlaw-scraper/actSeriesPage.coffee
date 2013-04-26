_ = require 'underscore'

# Libs.
{BasePage} = require './basePage'

# A single page of act series results.
#
# e.g. http://www.comlaw.gov.au/Series/C2004A00467
class @ActSeriesPage extends BasePage

  scraper: (done) =>
    acts = @extractActs()
    done null, acts

  extractActs: =>
    actSeriesTableId = '#ctl00_MainContent_SeriesCompilations_RadGrid1_ctl00'
    acts = @extractTable actSeriesTableId
    # Clean act title.
    _.each acts, (act) -> act.Title = act.Title.replace /\r\n.*$/, ''
    {acts}
