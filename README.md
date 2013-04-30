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

To run the entire process:

```
cd main
make
```

Or run an individual phase as follows:

`make arg='phase1'`

See `main/index.coffee` for descriptions of each phase.

## Modules

### comlaw-scraper

Downloads all acts from http://www.comlaw.gov.au.

### comlaw-to-markdown

Takes acts which have been exported from Microsoft Word into HTML, and converts them into Markdown format.

### amender

Updates a Australian Federal Parliament Consolidated Act from an Amendment Bill.

### to-markdown

Forked version of `to-markdown` with minor changes.

Converts HTML into Markdown.

### git-tools

Creates git repo(s) from Acts.

### austlii

Scrapes http://austlii.edu.au. Currently only used for retrieving a list of all consolidated acts.

## parlinfo

Scrapes http://parlinfo.aph.gov.au.

This will be used for monitoring bills before parliament.

---

A Node.js screen scraper for accessing legislation from the Parliament of Australia.

## Why?

Civic engagement is important. The operations of the Parliament of Australia are relatively inaccessible to the average citizen. By providing developers with easy access to the laws through a simple api will hopefully encourage developers to create new ways of involving people into the democractic process.

## How?

The Parliament does not currently provide any API to access legislation, although all legislation is made available across a few publically accessible websites:

This module scrapes data from the following websites:

- http://aph.gov.au
- http://comlaw.gov.au
- http://austlii.edu.au

## ComLaw

### Installation

`npm install openparl-law`

### Usage overview

`ComLaw = require 'openparl-law'`

## API

- `ComLaw.actSeries(id)` -
