# table

Beautiful rounded CLI tables for ZZ. Pure ZZ, zero dependencies.

```toml
zz add table
```

```zz
import table

func main() {
    table.new(["NAME", "AGE"])
        |> table.add_row(["Alice", "25"])
        |> table.add_row(["Bob", "30"])
        |> table.render()
        |> println()
}
```

```
╭───────┬─────╮
│ NAME  │ AGE │
├───────┼─────┤
│ Alice │ 25  │
│ Bob   │ 30  │
╰───────┴─────╯
```

The builder is a plain value. The idiomatic style is a `|>` pipeline
with a single binding — no rebind chain, no mutation to forget:

```zz
t := table.new(["NAME", "AGE"])
    |> table.add_row(["Alice", "25"])
    |> table.set_title("Users")
```

(Dotted chaining like `t.add_row(..).set_title(..)` parses and runs
on the VM. It needs a post-0.1.6 toolchain natively (method-dispatch
fixes landed in dev after 0.1.6); until your `zz` ships them, prefer
pipelines for anything that runs native. Plain
`t = table.add_row(t, …)` rebinding keeps working everywhere.)
See `examples/demo.zz` (`cd examples && zz install && zz run demo.zz`).

## One-liner

```zz
println(table.simple(["A", "B"], [["1", "2"]]))
```

## Styles

```zz
t = table.set_style(t, "rounded")  // default ╭─╮││╰─╯
t = table.set_style(t, "sharp")    // ┌─┐││└─┘
t = table.set_style(t, "heavy")    // ┏━┓┃┃┗┛
t = table.set_style(t, "double")   // ╔═╗║║╚╝
t = table.set_style(t, "markdown") // | pipes + --- separator
t = table.set_style(t, "minimal")  // no frame, ─ under header
t = table.set_style(t, "ascii")    // +-+|| fallback for dumb terminals
```

Unknown names fall back to `"rounded"`. `table.styles()` lists all seven.

## Alignment, padding, rows

```zz
t = table.set_align(t, 1, "right")   // "left" | "center" | "right", per column
t = table.set_align_all(t, "center") // every column at once
t = table.set_header_align(t, "center") // headers only; "auto" follows columns
t = table.set_padding(t, 2)          // spaces per side, clamped 0..8
t = table.set_row_lines(t, true)     // separator between every row
t = table.add_rows(t, rows)          // bulk append
t = table.from_rows(headers, rows)   // build in one call
```

## Title, footer, caption

```zz
t = table.set_title(t, "Stock")      // centered above the table
t = table.set_footer(t, ["Total", "14"])
t = table.set_caption(t, "src: db")  // plain line below the table
```

The footer renders after its own separator, before the bottom border —
the natural place for totals. Markdown renders the title as `# …`.

## Borders

```zz
t = table.set_outer_border(t, false) // no frame: no top/bottom rules, no sides
t = table.set_header_line(t, false)  // no separator between header and body
```

Inner column separators stay. Markdown drops its edge pipes (still
valid markdown); minimal has no frame, so the outer toggle is a no-op
there.

## Paging

```zz
t = table.set_max_rows(t, 10)  // body cap, overflow note counts hidden rows
t = table.set_row_offset(t, 20) // skip the first 20 body rows: page 3
```

Offset and cap compose into pages. The trailing `… +N more` note
counts every hidden row, above and below the window. Widths and
auto-alignment only see the shown window, so hidden rows never stretch
columns.

## Shape

```zz
table.row_count(t)   // body rows — total pages for your pager
table.col_count(t)   // rendered columns (headers/rows/footer max)
table.headers(t)     // header cells (a copy)
table.row(t, 0)      // one body row (a copy, [] when out of range)

t = table.with_row_numbers(t, "#") // 1-based index column at the left
t = table.transpose(t)             // swap rows and columns
t = table.hide_col(t, 2)           // drop a column (indices are current)
```

Index numbers are global, so pages keep stable numbering. Transpose
keeps display settings but resets per-column alignment to auto and
drops the footer. Hides compose: each index refers to the current
table.

## Data

```zz
table.col_sum(t, 0)   // 6.0 — numeric cells only, junk skipped
table.col_avg(t, 0)   // 2.0 — 0.0 when nothing numeric (never NaN)
table.col_num_count(t, 0) // how many cells voted

table.to_csv(t)   // headers + rows + footer, RFC quoting
table.to_json(t)  // [{"id": "1", …}, …], body rows keyed by headers
table.to_rows(t)  // headers + rows, round-trips with from_rows

t = table.fit_width(t, 80) // shrink caps until the frame fits 80 cols
```

Aggregates see the full column (paging never applies) and follow the
same numeric rule as auto-alignment. Exporters dump complete data:
truncation and paging never apply, the `… +N more` note is excluded,
and the footer joins CSV (as the last row) but not JSON (a display
total). `fit_width` only lowers caps, widest column first, floor 3 —
reduce padding first for more room.

## Colors

Pass `std.colors` output straight in. Widths are measured on the
visible text (ANSI `\e[…m` sequences count as 0), so columns stay
aligned under any styling:

```zz
import std.colors

t := table.new([colors.bold("NAME"), colors.bold("AGE")])
t = table.add_row(t, ["Alice", colors.green("25")])
table.print(t) // render + println in one call
```

## Functions

- `new(headers)` — empty table with headers.
- `from_rows(headers, rows)` — table with all rows at once.
- `simple(headers, rows)` — build and render immediately.
- `add_row(t, row)` / `add_rows(t, rows)` — append (short rows pad
  with `""`, long rows render whole, never panics).
- `from(rows, headers, f)` — build from any row type via a mapper
  closure; the `std.sqlz` bridge, pipeline-first argument order.
- `column(rows, f)` / `from_cols(headers, cols)` — build column by
  column, then transpose (short columns pad with `""`).
- `row_count` / `col_count` / `headers` / `row` — read shape (copies,
  total accessors).
- `with_row_numbers(header)` / `transpose` / `hide_col(col)` — reshape.
- `col_sum` / `col_avg` / `col_num_count` — column aggregates.
- `to_csv` / `to_json` / `to_rows` — full-data exporters.
- `fit_width(total)` — shrink caps to fit a terminal width.
- `set_style` / `set_align` / `set_align_all` / `set_header_align` /
  `set_padding` / `set_title` / `set_caption` / `set_footer` /
  `set_row_lines` / `set_outer_border` / `set_header_line` — builders above.
- `set_max_width` / `set_col_max_width` — truncation caps (`0` = off).
- `set_max_rows` / `set_row_offset` — paging (`0` = off / start).
- `from_json(headers, text)` — JSON array-of-arrays / array-of-objects.
- `from_csv(headers, text)` / `from_csv_delim(headers, text, delim)` —
  CSV via `std.csv` (`[]` derives headers from the first row).
- `render(t)` — string (trailing newline included).
- `print(t)` — `println(render(t))`.
- `styles()` — the seven style names.
- `visible_len(s)` — visible width (handy for your own layout next
  to a table).

Cells are single-line by design: embedded `\n`/`\t` fold to spaces so
one bad cell can never break the grid.

## `std.sqlz` support

Query rows flow into tables through one mapper closure. `from` takes
rows first, so `|>` pipelines read top to bottom:

```zz
import std.sqlz
import table

struct User { id: int, name: str }

mydb := sqlz.open(":memory:")
users: [User] = mydb.query("""SELECT id, name FROM users""")

users
    |> table.from(["ID", "NAME"], |u: User| [str(u.id), u.name])
    |> table.render()
    |> println()
```

Unannotated queries (`row{c0, c1, …}` dicts) work the same way with an
untyped mapper: `|r| [str(r.c0), str(r.c1)]`. Two smaller builders
compose column by column:

```zz
ids := table.column(users, |u: User| str(u.id))
t := table.from_cols(["ID", "NAME"], [ids, names])
```

See `examples/sqlz_demo.zz` (`cd examples && zz install && zz run
sqlz_demo.zz`) for filter-then-display pipelines.

## Truncation

```zz
t = table.set_max_width(t, 20)      // every column, 0 = off (default)
t = table.set_col_max_width(t, 2, 12) // one column, overrides global
```

Overlong cells truncate to a clean `…` (`"a very long…"`), ANSI-safe:
colors survive truncation and a reset is re-appended, so styling
never bleeds into borders. Widths, padding, and alignment all use the
post-truncation size.

## JSON

```zz
t := table.from_json(["id", "name"], "[{\"id\": 1, \"name\": \"a\"}]")
```

Array-of-arrays keep cell order; array-of-objects pick columns in
`headers` order (missing keys render blank, pass `[]` to derive
headers from the first object's keys). Numbers keep their text,
booleans print true/false, null and nesting render blank. Total:
invalid JSON yields a headers-only table, never an error.

## CSV

```zz
t := table.from_csv(["ID", "NAME"], "1,alice\n2,bob\n")
t := table.from_csv([], "id,name\n1,a\n")      // headers from first row
t := table.from_csv_delim(["A", "B"], "1;2\n", ";") // custom delimiter
```

Parsing rides on `std.csv` (RFC4180: quoted commas, doubled quotes),
so anything it reads renders. The first row is data — pass headers
explicitly or `[]` to take them from row one. Total like JSON:
invalid input yields a headers-only table. Round-trips with `to_csv`.

## Tests

`zz test` runs 89 checks: golden rounded output, per-column
alignment (incl. sticky `set_align_all`), header alignment, border
toggles across styles, row-offset paging, captions, shape accessors,
index columns, transpose and hide goldens, footer separator,
title, all seven glyph sets, fallback paths, uneven rows, empty
tables, newline folding, ANSI-safe widths, bulk APIs, row lines,
padding clamps, five `std.sqlz` bridge checks (struct rows, `|>`
pipelines, unannotated rows, `column`/`from_cols`, empty results),
eleven v0.2.0 checks (truncation goldens, per-column caps, colored
truncation without bleed, markdown/minimal truncation, JSON shapes,
derived headers, invalid-JSON empties, pipeline fluency), plus
eighteen v0.3.0 checks (header goldens, frameless/borderless outputs,
offset windows and page counts, width isolation, caption goldens),
plus ten v0.4.0 checks (accessors incl. copy isolation, index goldens
and page stability, transpose goldens incl. ragged input, hide goldens
incl. footer shift, shape pipeline), plus thirteen v0.5.0 checks
(aggregates incl. junk-skipping and divide-by-zero, CSV goldens and
window independence, JSON goldens and escaping, rows round-trip, fit
shrink/floor/untouched paths), plus eight v0.6.0 checks (CSV goldens,
derived headers, quoted fields, ragged rows, delimiter variant,
empty-input empties, CSV round-trip).
