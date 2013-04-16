start
  = items

items
  = item*

// A single amendment.
item
  = ih:itemHeading '\n' a:action { return {itemHeading:ih, action:a} }

// e.g. 1 Subsection 5(1) (definition of marriage)
itemHeading
  = itemNo:[0-9]* _ u:unit
  { return {itemNo: itemNo.join(''), unit: u} }

// Unit
// ----

// Identifies the affected unit.
// e.g. Subsection 5(1) (definition of marriage)
unit
  = ut:unitType _ un:unitNo sun:subUnitNo* _? ud:unitDescriptor?
  { return {unitType:ut, unitNo: un, subUnitNos: sun, unitDescriptor: ud} }


unitType
  = (
    'chapter'i
  / 'section'i
  / 'subsection'i
  / 'paragraph'i
  / 'note'i
  / 'penalty'i
  / 'table'i
  / 'table item'i
  / 'table cell'i
  / 'definition'i
  )

// e.g. 1
unitNo
  = un:[0-9a-zA-z]+ { return un.join('') }

// e.g. (1)(a)
subUnitNo
  = '(' sun:[0-9a-zA-Z]+ ')' { return sun.join('') }

// e.g. (definition of marriage)
unitDescriptor
  = '(' ud:[0-9a-zA-Z ]+ ')' { return ud.join('') }

// Action
// ------

action
  = al:actionLine
  '\n'? ac:actionContents?
  { return {line: al, body: ac} }

repeal
  = 'Repeal' _ ('the' _)? unitType ',' _ 'substitute:'
  { return {action: 'repeal+substitute'} }

repealUnit
  = 'Repeal' _ ('the' _)? unitType '.'
  { return {action: 'repeal'} }

quotedText
  = '“' s:string '”' { return s }

omit
  = 'Omit' _ omit:quotedText ',' _ 'substitute' _ substitute:quotedText '.'
  { return {action: 'omit+substitute', omit: omit, substitute: substitute} }

position
  = (
    'after'i
  / 'before'i
  )

// e.g After “or husband”, insert “, or partner”.
insert
  = p:position? _ subject:quotedText ',' _ 'insert' _ object:quotedText '.'
  { return {action: 'insert', position: p, subject: subject, object: object} }

actionLine
  = repeal / repealUnit / omit / insert

actionContents
  = text

char
  = .

// Use this to capture quoted text.
string
  = chars:[^“”]+ { return chars.join(""); }

text
  = chars:char+ { return chars.join(""); }

// One or more whitespace.
_
  = [ \t]+
