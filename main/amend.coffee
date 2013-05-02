logger = require('onelog').get 'Amend'

fs = require 'fs'
temp = require 'temp'

{Amender} = require 'amender'
{APH} = require 'aph'
{ComLaw} = require 'comlaw-scraper'

recode = (file) ->
  return null unless fs.existsSync file
  {Iconv} = require 'iconv'
  str = fs.readFileSync file
  iconv = new Iconv 'ISO-8859-1', 'UTF-8'
  buffer = iconv.convert str
  ret = buffer.toString()
  ret = ret.replace /[ÒÓ]/g, '"'
  ret = ret.replace /Õ/g, ' '
  ret = ret.replace /&#8209;/g, '-'
  #ret = ret.replace /&#146;/g, '\''
  ret

class @AmendRunner

  @amend: (amendmentBillId, done) ->
    #amender = new Amender
    logger.info "Applying amendment bill: #{amendmentBillId}"

    # Download amendment as HTML.
    await APH.downloadFirstReadingAndConvertToHTML {id: amendmentBillId}, defer e, htmlPath, data

    # Convert amendment to UTF-8.
    # TODO: This should move into Amender.
    amendmentHtml = recode htmlPath
    # Remove html comments.
    amendmentHtml = amendmentHtml.replace /<!--[\s\S]*?-->/g, ''
    amendmentHtml = amendmentHtml.replace /<o:p>[\s\S]*?<\/o:p>/g, ''
    p = temp.path(suffix: '.html')
    fs.writeFileSync p, amendmentHtml
    console.log p

    # Get the latest versions of each act.
    amender = new Amender amendmentHtml
    acts = amender.getAmendedActs()
    actsInput = {}
    for actTitle in acts
      logger.info 'Getting id from title'
      await ComLaw.getComLawIdFromActTitle actTitle, defer e, seriesId, results
      id = results.acts[0].comLawId
      logger.info 'Scraping html'
      await ComLaw.downloadAct id, defer e, actData
      actsInput[actTitle] = actData.data.html

    # Apply amendments to acts.
    logger.info 'Applying amendments'
    await amender.amend actsInput, defer e, actsOutput
    return done e if e

    done null, actsOutput

  downloadAmendment: (done) ->
    logger.debug 'Downloading amendment'

  getAmendmentTarget: (data) ->

