## Usage

Run `nodemon htmlToMarkdown.coffee`

### Get list of styles from Word Document

Enable Developer ribbon in Microsoft Word.

`File > Options > Customize Ribbon > Developer`

Create a new macro, add this code and press run.

```
Dim s As Style
For Each s In ActiveDocument.Styles
    If Not s.BuiltIn Then
        Debug.Print s.NameLocal
    End If
Next
```

You might need to show the Immediate window to get the output.

### Convert styles into CoffeeScript hash for mapping purposes.

Copy and paste into a text file called 'styles.txt'

Run `coffee stylesToCoffee.coffee`

You will need to modify some of the output by hand to match it up with the
styles used in the html. Lots of characters are invalid css class names.

## Dev workflow for creating a Word parser

use nodemon to run code continously

use Marked for OSX to watch the output file

use chrome inspector to examine html dom

## `to-markdown` module bugs

- strong/em inside a table should not be changed to Markdown format
-

    <p class="MsoNormal"><img width="152" height="112" src="MarriageAct1961_WD02_image001.gif"></p>

becomes

    <figure>
    <img src="http://www.comlaw.gov.au/Details/C2012C00837&lt;b id=" firstdiff"="">.html/Html/MarriageAct1961_WD02_image001.gif?v=104541" alt=""&gt;</figure>

### TODOS

- turn tables into Markdown tables

## Conversion

textutil will not work - removes too much data

libre office exports ok html but the html has problems rendering in chrome. not such an issue.

osx word exports the nicest. and the parser is already implemented for it.

most new bills have msword exported html available on comlaw anyway.

aspose.words produces html without classes - useless. aspose might be useful for reading styles though without showing window.

## Get Styles

c# app using word.interop library running on windows. problem is that it always opens up a copy of word!

aspose.words might help here, or another library.

perhaps use a bulk conversion from doc to docx then use xml lib.

http://blogs.msdn.com/b/ericwhite/archive/2008/09/19/bulk-convert-doc-to-docx.aspx

## Notes

Other options to explore:

http://www.docx4java.org/trac/docx4j

## Conversion Notes

- For the Aged Care Act we convert all characters we can't find to enspaces.
  This means some commas and thigns are missing.
