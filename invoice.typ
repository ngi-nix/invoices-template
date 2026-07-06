#set page(paper: "a4", margin: (x: 0.6cm, y: 1.5cm), numbering: "1", number-align: right)
#set text(font: "Roboto", size: 10pt)

#let format_euro(amount) = {
  let s = str(calc.round(amount, digits: 2))
  let parts = s.split(".")
  let int_part = parts.at(0)
  let frac_part = if parts.len() > 1 { parts.at(1) } else { "0" }
  if frac_part.len() == 1 { frac_part = frac_part + "0" }
  "€ " + int_part + "," + frac_part
}

#let format_num(amount) = {
  let s = str(calc.round(amount, digits: 2))
  let parts = s.split(".")
  let int_part = parts.at(0)
  let frac_part = if parts.len() > 1 { parts.at(1) } else { "0" }
  if frac_part.len() == 1 { frac_part = frac_part + "0" }
  int_part + "," + frac_part
}

#let data = csv("build/invoice_data.csv")
#let header = data.at(0)
#let rows = data.slice(1)

#let total_cost = 0.0
#let total_hours = 0.0
#for row in rows {
  total_hours += float(row.at(1))
  total_cost += float(row.at(4))
}
#let total_formatted = format_euro(total_cost)
#let total_hours_formatted = format_num(total_hours)

// Addresses
#grid(
  columns: (1fr, 1fr),
  [
    *Stichting NixOS Foundation* \
    Korte Lijnbaanssteeg 1-4318 \
    1012 SL \
    Amsterdam \
    The Netherlands
  ],
  align(right)[
    *[Contributor Name]* \
    [Address Line 1] \
    [Address Line 2] \
    [City, State, Zip] \
    [Country]
  ]
)

#v(1cm)

#let meta = json("build/invoice_meta.json")
#set document(title: meta.invoice_title, author: "[Contributor Name]", date: none)
// Right-align Invoice Date to Payment Method
#align(right)[
  #grid(
    columns: (8em, auto),
    row-gutter: 0.5em,
    align: (left, right),
    [Invoice Date], meta.invoice_date,
    [Due Date], meta.due_date,
    [Amount Due], [*#total_formatted*],
    [Payment Method], [Bank Transfer]
  )
]

#v(1cm)

// Left-align Beneficiary details below the Invoice details
#grid(
  columns: (50%, 1fr),
  row-gutter: 0.5em,
  [*Beneficiary*], [*[Contributor Name]*],
  [*[Payment Detail 1 (e.g., Account No., IBAN)]*], [*[Detail 1 Value]*],
  [*[Payment Detail 2 (e.g., SWIFT, Routing No.)]*], [*[Detail 2 Value]*],
  [*Remittance Text*], [Invoice for #meta.project_name #meta.period total of #total_formatted]
)

#v(1cm)

// Max width table, breakable, green outer border
#table(
  columns: (4.5fr, 1.3fr, 1.5fr, 1.3fr, 1.5fr),
  inset: 8pt,
  align: (left, right, center, right, right),
  stroke: (x, y) => {
    let c = rgb("#356854")
    let s = 0.5pt + c
    (
      top: if y == 0 { s } else { none },
      bottom: if y == rows.len() + 1 { s } else { none },
      left: if x == 0 { s } else { none },
      right: if x == 4 { s } else { none },
    )
  },
  fill: (col, row) => {
    if row == 0 {
      rgb("#356854") // Header dark green
    } else if row == rows.len() + 1 {
      rgb("#ccd9d4") // Total light green
    } else if calc.rem(row, 2) == 0 {
      rgb(246, 248, 249) // Alternate blue
    } else {
      white
    }
  },
  ..header.map(hdr => {
    let has_icon = hdr != "Notes"
    let icon = if hdr == "Hours" { "#" }
      else if hdr == "Date" { box(image("icons/icon_calendar.svg", height: 0.9em), baseline: 15%) }
      else if hdr == "Rate" { box(image("icons/icon_cash.svg", height: 0.9em), baseline: 15%) }
      else if hdr == "Cost" { box(image("icons/icon_cash.svg", height: 0.9em), baseline: 15%) }
      else { none }
    text(fill: white, weight: "bold")[
      #if has_icon {
        icon
        h(1.5em)
      }
      #hdr
    ]
  }),
  ..rows.flatten().enumerate().map(p => {
    let (i, cell) = p
    let col = calc.rem(i, 5)
    if col == 1 { format_num(float(cell)) }
    else if col == 3 or col == 4 { format_euro(float(cell)) }
    else { cell }
  }),
  align(right)[*TOTAL*], [*#total_hours_formatted*], meta.invoice_date, [], [*#total_formatted*]
)
