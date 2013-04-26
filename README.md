# Open Parliament Tools

_Scripts to initially populate the law repository and keep it up to date._

---

All modules written in CoffeeScript for Node.js.

Separate modules are used for different parts of functionality.

`main/index.coffee` provides an api to common operations involving the other modules.

## Usage

To run the entire process:

```
coffee main
```

## comlaw-scraper

Downloads all acts from http://www.comlaw.gov.au.

## comlaw-to-markdown

Converts Word-exported act html to Markdown.

## amender

Updates a Australian Federal Parliament Consolidated Act from an Amendment Bill

## to-markdown

Forked version of `to-markdown` with minor changes.



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
