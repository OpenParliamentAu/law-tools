# Open Parliament Tools

_Scripts to initially populate the law repository and keep it up to date._

---

All modules written in IcedCoffeeScript for Node.js.

Separate modules are used for different parts of functionality.

`main/index.coffee` provides an api to common operations involving the other modules.

## Usage

`npm install -g iced-coffee-script`
`npm install`

Install [SquidMan](http://squidman.net/squidman/) for OSX and run on `http://localhost:8080`. You can use any proxy you like.

To view command line interface options run:

```
cd main
make
```

## Modules

Here are the modules that we use. For each their is an indication of the state of the tests. If the status is "Good", you can generally run `make test` and tests will run.

### comlaw-scraper

Downloads all acts from http://www.comlaw.gov.au.

Tests: None.

### comlaw-to-markdown

Takes acts which have been exported from Microsoft Word into HTML, and converts them into Markdown format.

Tests: Good.

### amender

Updates a Australian Federal Parliament Consolidated Act from an Amendment Bill.

Tests: None.

### to-markdown

Forked version of `to-markdown` with minor changes.

Converts HTML into Markdown.

### git-tools

Creates git repo(s) from Acts.

### austlii

Scrapes http://austlii.edu.au. Currently only used for retrieving a list of all consolidated acts.

## aph

Scrapes http://aph.gov.au and http://parlinfo.aph.gov.au

This will be used for monitoring bills before parliament.
