path = require 'path'
fs = require 'fs'

root = @

# All paths in this hash are joined with the fixtures dir.
@fixtures =

  marriageAct:
    htmlFile: 'marriage-act-1961/C2012C00837.html'
    fileMappings: 'marriage-act-1961/files.coffee'
    styleMappings: 'marriage-act-1961/styles.coffee'
    opts:
      convertEachRootTagSeparately: true

  agedCareAct:
    htmlFile: 'aged-care-act-1997/C2012C00914.osxword.htm'
    fileMappings: 'aged-care-act-1997/files.coffee'
    styleMappings: 'aged-care-act-1997/styles.coffee'
    # DEBUG: Change the root to restrict how much markdown is generated.
    opts:
      root: '.WordSection4'
      convertEachRootTagSeparately: false

  incomeTaxAssessmentAct1997:
    htmlFile: 'income-tax-assessment-act-1997/C2013C00082VOL01.htm'
    fileMappings: 'income-tax-assessment-act-1997/files.coffee'
    styleMappings: 'income-tax-assessment-act-1997/styles.coffee'
    # DEBUG: Change the root to restrict how much markdown is generated.
    opts:
      root: '.WordSection3'
      convertEachRootTagSeparately: false

# TODO: Change this to environment var or something.
@fixturesDir = path.resolve '/Users/Vaughan/dev/opendemocracy-fixtures'

@getAllFixturesForAct = (actSlug) ->
  fs.readdirSync path.join fixturesDir, actSlug

@defaultOpts =
  linkifyDefinitions: true
  debugOutputDir: path.join __dirname, 'tmp/singleFile'
  markdownSplitDest: path.join __dirname, 'tmp/multipleFiles/'
  #disabledFilters: ['definition']
  styleMappings: require path.join root.fixturesDir, 'styles.coffee'

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
