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

    # If we mistakenly load a non-principal act, we want to follow the link
    # to the principal act...

    # TODO
    #principalActEl = $ '#ctl00_MainContent_pnlPrincipal'
    #if principalActEl.length
    #  acts.push
    #    Title: principalActEl.find('#ctl00_MainContent_hlPrincipal')?.text()
    #    ComlawId: principalActEl.find('ctl00_MainContent_lblPrincipalID')?.text()

    {acts}
