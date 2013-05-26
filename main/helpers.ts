///<reference path='./ts-definitions/DefinitelyTyped/node/node.d.ts'/>

var fs = require('fs')
var temp = require('temp')
var async = require('async')
var logger = require('onelog').get('Amend')
var sync = require('asyncblock')
var ComLaw = require('comlaw-scraper').ComLaw

var deferGetArray = function (...argNames: string[]) {
  var _ = require('underscore')
  var defer = sync.defer()  // function that takes err and one argument
  return function (err: Error, ...args: any[]) {    // function that takes err and any number of additional arguments
    var obj = _.object(argNames, args)
    defer( err, obj )
  }
}

export class Helpers {

  static recode (file) {
    if ( !fs.existsSync(file) ) return null
    var Iconv = require('iconv').Iconv
    var str = fs.readFileSync(file)
    var iconv = new Iconv('ISO-8859-1', 'UTF-8')
    var buffer = iconv.convert(str)
    var ret = buffer.toString()
    ret = ret.replace(/[ÒÓ]/g, '"')
    ret = ret.replace(/Õ/g, ' ')
    ret = ret.replace(/&#8209;/g, '-')
    //ret = ret.replace(/&#146;/g, '\'')
    return ret
  }

  static convertAmendmentToUTF8 (htmlPath) {
    // Convert amendment to UTF-8.
    // TODO: This should move into Amender.
    var amendmentHtml = Helpers.recode(htmlPath)
    // Remove html comments.
    amendmentHtml = amendmentHtml.replace(/<!--[\s\S]*?-->/g, '')
    amendmentHtml = amendmentHtml.replace(/<o:p>[\s\S]*?<\/o:p>/g, '')
    var p = temp.path({suffix: '.html'})
    fs.writeFileSync(p, amendmentHtml)
    return amendmentHtml
  }

  static getAmenderInputFromActTitles (actTitles, done) { sync( flow => {
    var actsInput = {}
    actTitles.map( actTitle => {
      logger.info('Getting id from title')
      console.log (actTitle, actTitles)
      var result: ActSeriesResult = ComLaw.getComLawIdFromActTitle(actTitle).sync(['seriesId', 'results'])
      var id = result.results.acts[0].comLawId
      logger.info('Scraping html')
      var actData: ActData = ComLaw.downloadAct(id).sync()
      actsInput[actTitle] = actData.data.html
    })
    done(null, actsInput)
  })}

}

interface ActData {
  data: { html: any; };
}

interface ActSeriesResult {
  seriesId: string;
  results: { acts: any; };
}
