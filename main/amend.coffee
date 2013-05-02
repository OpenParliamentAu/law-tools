logger = require('onelog').get 'Amend'
{Amender} = require 'amender'
{APH} = require 'aph'

class @AmendRunner

  amend: (amendmentBillId, done) ->
    #amender = new Amender
    logger.info "Applying amendment bill: #{amendmentBillId}"

    # Download amendment as HTML.
    await APH.downloadFirstReadingAndConvertToHTML {id: 's905'}, defer e, htmlPath, data
    amendmentHtml = fs.readFileSync htmlPath, 'utf-8'

    # Get html of latest consolidated act.
    # TODO: This may be multiple acts. Currently not supported by Amender.
    act = originalHtml: actOriginalHtml

    await amender.amend act, amendmentHtml, defer e, md, html
    return done e if e

    done()

  downloadAmendment: (done) ->
    logger.debug 'Downloading amendment'

  getAmendmentTarget: (data) ->

