module.exports =

  1:
    item:
      line1: "1 Subsection 5(1)(2) (definition of marriage)"
      line2: "Repeal the definition, substitute:"
      line3: "marriage means the union of two people, to the exclusion of all others, voluntarily entered into for life."
    expected:
      itemNo: "1"
      unit:
        unitType: "Subsection"
        unitNo: "5"
        subUnitNos: ["1", "2"]
        unitDescriptor: "definition of marriage"
      action:
        type: "repeal+substitute"
      body: "marriage means the union of two people, to the exclusion of all others, voluntarily entered into for life."

  2:
    item:
      line1: "2  Subsection 45(2)"
      line2: "After “or husband”, insert “, or partner”."
    expected:
      itemNo: "2"
      unit:
        unitType: "Subsection"
        unitNo: "45"
        subUnitNos: ["2"]
        unitDescriptor: ""
      action:
        type: 'insert'
        position: "After"
        subject: "or husband"
        object: ", or partner"
      body: undefined

  3:
    item:
      line1: "3  Subsection 46(1)"
      line2: "Omit “a man and a woman”, substitute “two people”."
    expected:
      itemNo: "3"
      unit:
        unitType: "Subsection"
        unitNo: "46"
        subUnitNos: ["1"]
        unitDescriptor: ""
      action:
        type: "omit+substitute"
        omit: "a man and a woman"
        substitute: "two people"
      body: undefined

  6:
    item:
      line1: "6  Section 88EA"
      line2: "Repeal the section."
    expected:
      itemNo: "6"
      unit:
        unitType: "Section"
        unitNo: "88EA"
        subUnitNos: []
        unitDescriptor: ""
      action:
        type: "repeal"
      body: undefined
