#
# make test arg='test/amend.coffee'
#

{AmendRunner} = require '../amend'

# Marriage Equality Amendment Bill 2013
amendmentBillId = 's905'

describe 'Amend Runner', ->

  before ->
    @runner = new AmendRunner amendmentBillId

  it 'should download amendment', (done) ->
    @runner.amend amendmentBillId, done

  it 'acquire current html of act', ->
  it 'amend act', ->
  it 'branch repo', ->
  it 'commit change', ->
  it 'push remotely', ->

