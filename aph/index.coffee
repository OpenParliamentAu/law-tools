url = (id) -> "http://www.aph.gov.au/Parliamentary_Business/Bills_Legislation/Bills_Search_Results/Result?bId=#{id}"

uuid = require 'node-uuid'
mkdirp = require 'mkdirp'
path = require 'path'
fs = require 'fs'
wrench = require 'wrench'
_ = require 'underscore'
request = require 'request'
{exec} = require 'child_process'

{APHBillPage} = require './aphBillsSearchResult'
{Util} = require 'op-util'

class @APH

  @scrapeBillHomePage: (opts, done) ->
    args = if opts.html? then {html: opts.html} else {url: url(opts.id)}
    page = new APHBillPage args
    await page.scrape defer e, data
    return done e if e
    done null, data

  # Download first reading to temp file and return path to file.
  @downloadFirstReading: (opts, done) ->
    await APH.scrapeBillHomePage opts, defer e, data
    return done e if e

    # Get url.
    doc = _.findWhere data.textOfBill, title: 'First reading'
    url = doc.docs['Word format']
    isDocx = url.match 'fileType=application%2Fvnd%2Eopenxmlformats%2Dofficedocument%2Ewordprocessingml%2Edocument'
    if isDocx then ext = '.docx'

    # Download to temp path.
    tempFile = getTempFileName() + ext
    await downloadFile tempFile, url, defer e
    return done e if e

    done null, tempFile, data

  # Move and renmae file to temp location. For testing purposes.
  # Returns new file path.
  @copyFileToTempLocation: (src) ->
    dest = getTempFileName() + path.extname(src)
    fs.createReadStream(src).pipe(fs.createWriteStream(dest))
    dest

  # Use automator to convert Word to HTML.
  @convertWordToHTML: (wordFilePath, done) ->
    automatorScriptPath = path.join __dirname, 'automator/word-to-html.app'

    # These are the two files which will be generated.
    # This is determined by the Word Automator workflow. We can't change it.
    wordFileBase = wordFilePath.slice(0, -path.extname(wordFilePath).length)
    fileDest = wordFileBase + '.html'
    folderDest = wordFileBase + '_files'

    # Run command.
    cmd = "automator -i #{wordFilePath} #{automatorScriptPath}"
    console.log 'Running cmd', cmd
    await exec cmd, defer e, stdout, stderr
    return done e if e
    console.log stdout, stderr
    done null, fileDest

  # Returns path to first reading html file and bill meta-data.
  @downloadFirstReadingAndConvertToHTML: (opts, done) ->
    await APH.downloadFirstReading opts, defer e, tempPath, data
    return done e if e
    await APH.convertWordToHTML tempPath, defer e, htmlPath
    return done e if e
    done null, htmlPath, data

# TODO: Make sure done isn't called twice.
downloadFile = (dest, url, done) =>
  mkdirp.sync path.dirname dest
  request(url).pipe(fs.createWriteStream dest)
    .on 'error', (e) ->
      done e
    .on 'close', ->
      done()
    .on 'end', ->
      done()

getTempFileName = ->
  # Create temp file name.
  workDir = Util.getTempDir()
  filename = path.join workDir, uuid.v1()
  mkdirp.sync workDir
  filename
