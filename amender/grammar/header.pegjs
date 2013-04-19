start
  = ih:itemHeading { return ih }

// e.g. 1 Subsection 5(1) (definition of marriage)
itemHeading
  = itemNo:[0-9]+ _ u:(nonUnitHeader / ofUnit / unit)
  { return {itemNo: itemNo.join(''), unit: u} }

// Unit
// ----

// Identifies the affected unit.
// e.g. Subsection 5(1) (definition of marriage)
unit
  = ('the' _)? ut:unitType _ un:unitNo? sun:subUnitNo* _? ud:unitDescriptor?
  { return {unitType:ut, unitNo: un, subUnitNos: sun, unitDescriptor: ud} }

ofUnit
  = unitType 's'? _ (unitNo / romanUnitNo) _ 'of' _ unit

nonUnitHeader
  = nuh:(
    'Regulations may make consequential amendments of Acts'i
  / 'Application—ministers of religion'i
  )
  { return {nonUnitHeader: nuh} }

unitType
  = (
    'chapter'i
  / 'section'i
  / 'subsection'i
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
  )

// e.g. 1
unitNo
  = un:[0-9a-zA-z\-]+ { return un.join('') }

romanUnitNo
  = [IVXLCDM]+ { return { roman: un.join('') } }

// e.g. (1)(a)
subUnitNo
  = '(' sun:[0-9a-zA-Z]+ ')' { return sun.join('') }

// e.g. (definition of marriage)
unitDescriptor
  = '(' ud:[0-9a-zA-Z \xA0]+ ')' { return ud.join('') }

// One or more whitespace.
_
  = [ \t\xA0]+
