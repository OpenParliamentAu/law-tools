require('typescript-require')()
require('asyncblock').enableTransform()

logger = require('onelog').get 'Amend'

fs = require 'fs'
temp = require 'temp'

{Amender} = require 'amender'
{APH} = require 'aph'
{ComLaw} = require 'comlaw-scraper'
{Helpers} = require './helpers'

class @AmendRunner

  @amend: (amendmentBillId, done) ->
    logger.info "Applying amendment bill: #{amendmentBillId}"

    # Download amendment as HTML.
    await APH.downloadFirstReadingAndConvertToHTML {id: amendmentBillId}, defer e, htmlPath, data
    amendmentHtml = Helpers.convertAmendmentToUTF8 htmlPath

    # Get latest versions of all acts which this amendment amends.
    amender = new Amender amendmentHtml
    actTitles = amender.getAmendedActs()
    logger.info 'Amending acts:', actTitles

    await Helpers.getAmenderInputFromActTitles actTitles, defer e, actsInput

    # Apply amendments to acts.
    logger.info 'Applying amendments'
    await amender.amend actsInput, defer e, actsOutput
    return done e if e

    done null, actsOutput

  downloadAmendment: (done) ->
    logger.debug 'Downloading amendment'

  getAmendmentTarget: (data) ->

