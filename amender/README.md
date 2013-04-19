# Amender

*Updates a Australian Federal Parliament Consolidated Act from an Amendment Bill*

## Goals

The goal is to allow the general public to track the progress of bills through parliament.

The strategy is to produce Markdown diffs for amendments currently before parliament.

## Method

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

`make`

### Parser

`make arg='-g Parser'`

## Ideas

The rationale for moving from Word to Markdown is primarily for better diffs. However, we lose a lot of semantic information when converting from Word to Markdown.

The process of converting from Word to Markdown involves the creation of an cleaned HTML document which is then converted to Markdown with a generic HTML to Markdown script.

An idea is to add as much semantic information as possible to the intermediate HTML document, save this to version control too, and when amendments need to be made we can make them to this HTML document, and then generate the Markdown.

## Glossary

Office of Parliamentary Counsel (OPC) - Responsible for drafting consolidated acts when new amendments are passed.
