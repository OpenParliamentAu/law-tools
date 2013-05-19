libxmljs = require 'libxmljs'

@libxmljs: (xml) ->
  doc = libxmljs.parseXml xml
  majorHeadings = doc.get '//major-heading'
  console.log majorHeadings
  for h in majorHeadings
    console.log h.text()

@xml2js: (xml) ->
  await parseString xml, {explicitArray: true}, defer e, r
  #console.log inspect r, null, 3
  console.log r.debates
  #for debates of r
  #  console.log node
