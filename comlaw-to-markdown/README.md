# ComLawToMarkdown

_As of 25/04/2013_

Takes the HTML which has been exported from Microsoft Word and converts it into Markdown-compatible HTML, to allow for clean conversion into Markdown.

This library is currently specific to bills from http://comlaw.gov.au but could be made more generic in the future.

## Setup

Obtain fixtures from GitHub.

    git clone https://github.com/OpenParliamentAu/law-fixtures.git

Add location of fixtures as environment variable. Replace `fixtures-dir` with the
directory where you cloned the fixtures repo to. Mine is at `~/dev/law-fixtures`.

    echo 'export OPENPARL_FIXTURES="<fixtures-dir>"' >> ~/.bashrc

## Test

`make test`

## Dev Workflow

In `examples/convertAct.coffee` set `act` to the act you want to compile.

Run `nodemon examples/convertAct.coffee`.

Hack!

Regression test with `make test`.

If there are errors, follow the steps to resolve the regressions.

Commit!
