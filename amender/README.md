# Amender

*Updates a Australian Federal Parliament Consolidated Act from an Amendment Bill*

## Usage

`npm install`

```
{Amender} = require 'amendment'
amender = new Amender
act =
  originalHtml: <html string of previous consolidated act scraped from comlaw.gov.au>
amendment = <html string of amendment act scraped from comlaw.gov.au>
amender.amend act, amendment, (e, md, html) ->
  throw e if e
  console.log md
```

## Why?

The progress of bills through each house of parliament can be represented using branches and forking on GitHub.

We want to view diffs of bills before parliament to show the changes in context and allow discussion from the general public (analagous to code reviews in the programming world), as well as providing links to relevant parlimentary debates, committee reports, and status updates.

Currently ComLaw only creates consolidated acts after a bill is assented. This means we can't easily create diffs for bills currently before parliament - the time when they are most useful.

So the options are manually modifying consolidated acts or automating the process.

## How?

Amendment bills are written in plain English. For example:

```
Schedule 3—Spent legislation
Part 1—Amendments
Aged Care Act 1997
1  Subparagraph 16‑2(3)(g)(iii)
Omit “paid; or”, substitute “paid;”.
```

Amendments are drafted by the OPC. The OPC follows certain directions in drafting bills and uses consistent "forms" for amendments. For example above is referred to as the `omit` amendment form.

This allows us to parse amendments with relative ease.

After we have parsed the amendments, the next stage is locating the target unit and applying the amendment.

### Method

```
for each schedule
  for each part
    for each act
      for each item
        1. parse heading, action, body
        2. locate unit
        3. apply
```

## Discussion

First we parse the amendment act to work out the unit to be changed and the changes we need to make.

Then we must apply the change.

There are several places we can apply changes:

 - Word (.doc)
 - Word -> Word 2007 (.docx) (XML)
 - Word -> HTML
 - Word -> HTML -> Markdown

Our choice depends upon our ability to locate the unit to be changed.

The Word -> HTML has classes for each different unit type (e.g paragraph, subparagraph). We also already have scripts to move from this HTML to Markdown.

Working with HTML provides us with much more semantic information and it is convenient to work with a DOM using Cheerio.

A disadvantage is that diffs can only be generated against the latest consolidated act from ComLaw. However, ComLaw is quite fast[?] in making changes to consolidated acts once a law is passed so this may not be a problem.

## Test

### Integration

`make test`

### Parser

`make arg='-g Parser'`

## Ideas

The rationale for moving from Word to Markdown is primarily for better diffs. However, we lose a lot of semantic information when converting from Word to Markdown.

The process of converting from Word to Markdown involves the creation of an cleaned HTML document which is then converted to Markdown with a generic HTML to Markdown script.

An idea is to add as much semantic information as possible to the intermediate HTML document, save this to version control too, and when amendments need to be made we can make them to this HTML document, and then generate the Markdown.

## Glossary

 - Office of Parliamentary Counsel (OPC) - Responsible for drafting consolidated acts when new amendments are passed.
