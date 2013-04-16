path = require 'path'
fs = require 'fs'

root = @

# All paths in this hash are joined with the fixtures dir.
@fixtures =

  marriageAct:
    htmlFile: 'marriage-act-1961/C2012C00837.html'
    fileMappings: 'marriage-act-1961/files.coffee'
    opts:
      convertEachRootTagSeparately: true

  agedCareAct:
    htmlFile: 'aged-care-act-1997/C2012C00914.osxword.htm'
    fileMappings: 'aged-care-act-1997/files.coffee'
    # DEBUG: Change the root to restrict how much markdown is generated.
    opts:
      #root: '.WordSection2'
      #convertEachRootTagSeparately: false
      root: 'body'
      convertEachRootTagSeparately: true
x
  incomeTaxAssessmentAct1997:
    htmlFile: 'income-tax-assessment-act-1997/C2013C00082VOL01.htm'
    fileMappings: 'income-tax-assessment-act-1997/files.coffee'
    # DEBUG: Change the root to restrict how much markdown is generated.
    opts:
      root: 'body'
      convertEachRootTagSeparately: true

  fairWorkAct2009Vol1:
    htmlFile: 'fair-work-act-2009/C2013C00070VOL01.htm'
    fileMappings: 'fair-work-act-2009/files.coffee'
    opts:
      root: 'body'
      convertEachRootTagSeparately: true

  fairWorkAct2009Vol2:
    htmlFile: 'fair-work-act-2009/C2013C00070VOL02.htm'
    fileMappings: 'fair-work-act-2009/files.coffee'
    opts:
      root: 'body'
      convertEachRootTagSeparately: true

# TODO: Change this to environment var or something.
@fixturesDir = path.resolve '/Users/Vaughan/dev/opendemocracy-fixtures'

@getAllFixturesForAct = (actSlug) ->
  fs.readdirSync path.join fixturesDir, actSlug

@defaultOpts =
  linkifyDefinitions: true
  debugOutputDir: path.join __dirname, 'tmp/singleFile'
  markdownSplitDest: path.join __dirname, 'tmp/multipleFiles/'
  #disabledFilters: ['definition']
  #styleMappings: require path.join root.fixturesDir, 'styles.coffee'
  styleMappings: require path.join __dirname, '../styles/styles.coffee'
  cleanTables: true
  outputSplit: false

@getFileInfo = (act) ->
  htmlFilePath = path.join root.fixturesDir, act.htmlFile
  htmlBaseName = path.basename htmlFilePath, '.html'
  htmlFileNameWithExt = path.basename htmlFilePath
  fileMappings = require path.join root.fixturesDir, act.fileMappings
  {
    path: htmlFilePath
    base: htmlBaseName
    name: htmlFileNameWithExt
    fileMappings: fileMappings
  }
