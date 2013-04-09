# Australian federal laws

This Git repository contains all Australian federal laws in Markdown format.

The laws have been scraped from http://www.comlaw.gov.au.

## Structure

### How to organize repos

One question at the moment is whether to create a repository for each principal act or to just stick all acts in one repository.

All acts in one repository makes more sense as an amendment bill may modify many acts.

Also, because we are using the commit history to track changes to the law as closely as possible, perhaps we should separate this README.md file from the actual laws by placing the laws in a Git sub-module. Or we should use the wiki.

---

Each principal act is a Git repository.

The first consolidated act in the ComLaw database has been added as the first commit in each repository.

For each amendment to a principal act, the consolidated act at the time of said amendment has been added as a commit.

Consolidated acts have been prepared by http://www.comlaw.gov.au.

## Goal

This Git repository is for tracking legislative changes through commit history, and allowing public comment through GitHub code reviews and issues.

## Workflow

When a new amendment is proposed in Parliament, a new consolidated act incorporating its changes will be added as a pull-request.

If amendments are proposed to this amendment bill in the House or Senate, they will be added as a pull-request from either AusParliament/house or AusParliament/senate

When the amendment is adopted by Parliament, the pull-request will be merged.

## Maintenance

When developing software, your repo is generally your master representation of your codebase. With this project things are a little different.

Essentially a master version of the law does not exist. It is the compilation of the principal act and all subsequent amendments.

This project is simply mapping amendments written in English prose to git changesets.

The way we are doing this is by comparing consolidated acts prepared by ComLaw for each amendment to generate our commit history.

Because ComLaw has chosen to use Microsoft Word to prepare their consolidated acts, this makes file comparisons useless except if using the "Compare Documents" in Microsoft Word or LibreOffice.

For this reason, we have decided to convert all laws into Markdown format.

Therefore there may occasionally be mistranslations. If this occurs, the git history should be rewritten, rather than a new commit being made.


## Thanks

@bundesgit

AusParliament/law
AusParliament/law-docs
AusParliament/law-tools
