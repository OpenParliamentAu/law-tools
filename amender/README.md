# Amender

*Updates a Australian Federal Parliament Consolidated Act from an Amendment Bill*

## Test

`mocha`

## Ideas

The rationale for moving from Word to Markdown is primarily for better diffs. However, we lose a lot of semantic information when converting from Word to Markdown.

The process of converting from Word to Markdown involves the creation of an cleaned HTML document which is then converted to Markdown with a generic HTML to Markdown script.

An idea is to add as much semantic information as possible to the intermediate HTML document, save this to version control too, and when amendments need to be made we can make them to this HTML document, and then generate the Markdown.

## Glossary

Office of Parliamentary Counsel (OPC) - Responsible for drafting consolidated acts when new amendments are passed.
