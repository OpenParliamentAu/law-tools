start
  = a:actionLine { return a }

// Unit
// ----

unitType
  = (
    'chapter'i
  / 'section'i
  / 'subsection'i
  / 'division'i
  / 'subdivision'i
  / 'paragraph'i
  / 'subparagraph'i
  / 'note'i
  / 'penalty'i
  / 'table'i
  / 'table item'i
  / 'table cell'i
  / 'definition'i
  / 'schedule'i
  / 'part'i
  / 'clause'i
  ) 's'?

// Action
// ------

repeal
  = 'Repeal' _ ('the' _)? unitType ',' _ 'substitute:'
  { return {type: 'repeal+substitute'} }

repealUnit
  = 'Repeal' _ ('the' _)? unitType '.'
  { return {type: 'repeal'} }

quotedText
  = ('“' / '"') s:string ('”' / '"') { return s }

omit
  = 'Omit' _ omit:quotedText ',' _ 'substitute' _ substitute:quotedText '.'
  { return {type: 'omit+substitute', omit: omit, substitute: substitute} }

position
  = (
    'after'i
  / 'before'i
  )

// e.g After “or husband”, insert “, or partner”.
insert
  = p:position? _ subject:quotedText ',' _ 'insert' _ object:quotedText '.'
  { return {type: 'insert', position: p, subject: subject, object: object} }

// For when position to insert is specified in the header.
// e.g. Insert:
simpleInsert
  = 'Insert:' { return {type: 'simpleInsert'}; }

actionLine
  = repeal / repealUnit / omit / insert / simpleInsert

char
  = .

// Use this to capture quoted text.
string
  = chars:[^“”"]+ { return chars.join(""); }

text
  = chars:char+ { return chars.join(""); }

// One or more whitespace.
_
  = [ \t]+
