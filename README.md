# Open Parliament Tools

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
