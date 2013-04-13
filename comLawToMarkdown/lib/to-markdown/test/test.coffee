chai = require 'chai'
chai.should()
{toMarkdown} = require '../to-markdown'

fixture =
"""<b>X</b><em>Y</em>

<table><tr><td>
<i>A</i><b>B</b><strong>C</strong><em>D</em>
</td></tr>"""

expected =
"""**X**_Y_

<table><tr><td>
<i>A</i><b>B</b><strong>C</strong><em>D</em>
</td></tr></table>"""

describe 'to-markdown', ->
  it 'should not convert tags within tables', ->
    md = toMarkdown fixture
    md.should.equal expected

#cheerio = require 'cheerio'
#$ = cheerio.load("<body></body>")
#$('body').prepend '<colgroup><col/></colgroup>'
#$('body').prepend '<colgroup><col></col></colgroup>'
#$('body').prepend '<colgroup><col width="20"></col></colgroup>'
#console.log $.html()
