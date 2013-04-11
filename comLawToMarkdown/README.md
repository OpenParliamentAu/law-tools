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

### TODOS

- turn tables into Markdown tables
