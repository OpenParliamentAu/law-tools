# Vendor.
chai = require 'chai'
chai.should()

{fixtures} = require './helpers'
{setup, convert} = require './setup'

describe 'The converter', ->

  describe 'should not introduce regressions in', ->

    it 'when converting marriage act', (done) ->
      setup.call @, fixtures.marriageAct, =>
        convert.call @, 'marriage-act-1961/C2012C00837.md', done

    it 'when converting aged care act', (done) ->
      setup.call @, fixtures.agedCareAct, =>
        convert.call @, 'aged-care-act-1997/C2012C00914.osxword.md', done

    it 'when converting fair work act', (done) ->
      setup.call @, fixtures.fairWorkAct2009Vol1, =>
        convert.call @, 'fair-work-act-2009/C2013C00070VOL01.md', done

    #it 'when converting income tax assessment act 1997', (done) ->
    #  setup.call @, fixtures.incomeTaxAssessmentAct1997, done
    #  convert.call @, 'income-tax-assessment-act-1997/C2013C00082VOL01.md', done
