### Reverse-engineering http://www.aph.gov.au/

There are two ways to view bills:

1. http://parlinfo.aph.gov.au/
2. http://www.aph.gov.au/Parliamentary_Business/Bills_Legislation/Bills_before_Parliament

# http://parlinfo.aph.gov.au/

### feeds/rss.w3p

adv=yes;orderBy=customrank;page=0;query=Dataset%3AbillsCurBef;resCount=Default

adv=yes;orderBy=customrank;page=0;query=Dataset%3AbillsCurBef;resCount=100

adv=yes;orderBy=date-eFirst;page=0;query=Dataset%3AbillsCurBef;resCount=Default

* Max resCount is 200

## Basic Search

http://parlinfo.aph.gov.au/parlInfo/search/search.w3p;

<blank> - Basic search
adv=yes - Advanced Search

## Summary Search Results

http://parlinfo.aph.gov.au/parlInfo/search/summary/summary.w3p;

page=0;
query=something;
resCount=Default

http://parlinfo.aph.gov.au/parlInfo/search/summary/summary.w3p;page=0;query=something%20ParliamentNumber%3A%2243%22;resCount=Default

## View bill

http://www.aph.gov.au/Parliamentary_Business/Bills_Legislation/Bills_Search_Results/Result?bId=r5010

http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;

query=Id%3A%22legislation%2Fbills%2Fr5010_first-reps%2F0000%22;
query=Id:"legislation/bills/r5010_first-reps/0000";

rec=0

### search/display/display.w3p

**query**

Id:"legislation/bills/r5010_first-reps/0000";

- The last number is the schedule number



## http://www.aph.gov.au/Parliamentary_Business/Bills_Legislation/Bills_before_Parliament

*Home > Parliamentary Business > Bills and Legislation > Bills Search Results*

http://www.aph.gov.au/Parliamentary_Business/Bills_Legislation/Bills_Search_Results?
st=1&
sr=1&
q=&
ito=1&
expand=False&
drvH=7&
drt=2&
pnu=43&
pnuH=43&
f=28%2F09%2F2010&
to=06%2F04%2F2013&
bs=1&
pbh=1&
bhor=1&
pmb=1&
g=1&
ps=10

## Downloading a Bill as a Word Document

### URL

/parlInfo/download

/legislation/amend/r4863_amend_51523fc9-ab02-4fb8-855d-0f98804edb45

/upload_word

/7281_Electoral%20and%20Referendum%20Amdt%20(Improving%20Electoral%20Procedure)_DLP.docx

;fileType=application%2Fvnd%2Eopenxmlformats%2Dofficedocument%2Ewordprocessingml%2Edocument

### Download PDF

/parlInfo/download/legislation/amend/r4863_amend_51523fc9-ab02-4fb8-855d-0f98804edb45

/upload_pdf

/7281_Electoral%20and%20Referendum%20Amdt%20(Improving%20Electoral%20Procedure)_DLP.pdf

;fileType=application%2Fpdf

\#search=%22legislation/amend/r4863_amend_51523fc9-ab02-4fb8-855d-0f98804edb45%22

---

http://parlinfo.aph.gov.au//parlInfo/download/legislation/amend/r4863_amend_51523fc9-ab02-4fb8-855d-0f98804edb45/upload_pdf/7281_Electoral%20and%20Referendum%20Amdt%20(Improving%20Electoral%20Procedure)_DLP.pdf;fileType=application%2Fpdf