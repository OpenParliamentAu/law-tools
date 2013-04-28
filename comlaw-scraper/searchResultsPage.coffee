_ = require 'underscore'

# Libs.
{BasePage} = require './basePage'

# A single page of act series results.
#
# e.g. http://www.comlaw.gov.au/Search/A%20NEW%20TAX%20SYSTEM%20(AUSTRALIAN%20BUSINESS%20NUMBER)%20ACT%201999
class @SearchResultsPage extends BasePage

  scraper: (done) =>
    acts = @extractActs()
    done null, acts

  extractActs: =>
    tableId = '#ctl00_MainContent_RadGrid1_ctl00'
    acts = @extractTable tableId, SearchResultsPage.extractViewSeriesLink
    # Clean act title.
    _.each acts, (act) -> act.Title = act.Title.replace /\r\n.*$/, ''
    {acts}

  @extractViewSeriesLink: ($, $col, newRow) ->
    if el = $col.find("input[value='View Series']")
      onClickAttr = el.attr('onclick')
      matches = onClickAttr?.match /"\.\.\/Series\/(.*)"/
      if matches?.length
        newRow['seriesComLawId'] = matches[1]
