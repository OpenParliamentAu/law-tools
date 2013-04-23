start
  = ih:itemHeading { return ih }

// e.g. 1 Subsection 5(1) (definition of marriage)
itemHeading
  = itemNo:[0-9]+ _ p:position? _? u:(nonUnitHeader / ofUnit / unit)
  { return {itemNo: itemNo.join(''), unit: u, position: p} }

// Unit
// ----

// Identifies the affected unit.
// e.g. Subsection 5(1) (definition of marriage)
unit
  = ('the' _)? ut:unitType 's'? _ un:unitNo? sun:subUnitNos* _? ud:unitDescriptor?
  { return {unitType:ut, unitNo: un, subUnitNos: sun, unitDescriptor: ud} }

ofUnit
  = ut:unitType _ un:(romanUnitNo / unitNo) _ 'of' _ u:unit
  { return {ofUnit: true, unitType: ut, unitNo: un, unit: u} }

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
  ) // 's'?

// e.g. 1
unitNo
  = un:[0-9a-zA-z\-\u2011]+ { return un.join('') }

romanUnitNo
  = un:[IVXLCDM]+ { return { roman: un.join('') } }

// e.g. (1)(a)
subUnitNo
  = '(' sun:[0-9a-zA-Z]+ ')' { return sun.join('') }

subUnitNos
  = multipleSubUnitNos / subUnitNo

multipleSubUnitNos
  = a:subUnitNo _ 'and' _ b:subUnitNo
  { return [a, b]; }

// e.g. (definition of marriage)
unitDescriptor
  = '(' ud:[0-9a-zA-Z \xA0]+ ')' { return ud.join('') }

// One or more whitespace.
_
  = [ \t\xA0\u2002]+

position
  = (
    'after'i
  / 'before'i
  )
