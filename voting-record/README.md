# Voting Record

_Extracts votes from Australian Federal Parliament "Votes and Proceedings" documents_

OpenAustralia provides easily accessible directory of hansard as XML available here: http://openaustralia.github.io/openaustralia/download-xml-data.html

The hansard contains all votes when division was required in nicely formatted XML.

---

EDIT (20/05/2013):

The OpenAustralia XML in the `scrapedxml` dir is lossy. It has been changed to work with the UK web app.

The original XML is better for our purposes.

## Test

Test APH parser:

    make test arg="-g APH"

## Senate

Journals: http://www.aph.gov.au/Parliamentary_Business/Chamber_documents/Senate_chamber_documents/Journals_of_the_Senate
Daily Summary: http://www.aph.gov.au/About_Parliament/Senate/Powers_practice_n_procedures/guides/~/link.aspx?_id=CB93A7DD177D4F089BBC7A74BF6FCF3C&_z=z

Guide: http://www.aph.gov.au/About_Parliament/Senate/Powers_practice_n_procedures/guides/briefno18

## House of Representitives

Votes and Proceedings: http://www.aph.gov.au/Parliamentary_Business/Chamber_documents/HoR/Votes_and_Proceedings

## Federation Chamber


## Notes

OpenAustralia XML schemas (see aph-xml):

https://github.com/bruno/openaustralia-parser/tree/master/xml_schemas
