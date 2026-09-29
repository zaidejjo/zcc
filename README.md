# zcc — blazing-fast code counter (tokei clone, written in ZZ)

Counts code, comments, and blanks across 70+ languages, with Markdown
fence breakdowns, JSON output, and warm runs under 0.1s.

```sh
zcc [path] [flags]
```

## Flags

| Flag | Effect |
|------|--------|
| `--output json` | machine-readable JSON on stdout |
| `--only LANG` | count one language (`--only Rust`) |
| `--hidden` | include hidden files/dirs |
| `--no-ignore` | skip `.gitignore` rules (still skips `.git`) |
| `--no-cache` | always recount, don't read/write the cache |
| `--by-file` | list top files by lines after the table |
| `--top N` | files shown with `--by-file` (default 20) |
| `--help`, `--version` | |

`zcc init [--force]` writes the default `~/.config/zcc/config.json`
(Linux/macOS; `%APPDATA%\zcc\config.json` on Windows). Refuses to
overwrite without `--force`. A bare directory named `init` still
works as a path (`zcc ./init`).

`NO_COLOR=1` disables all color. Piped output keeps colors unless
disabled (strip with `--output json` for scripts, or set color off).

## Config file: `~/.config/zcc/config.json`

All customization lives in one JSON file (see `config.example.json`).
Missing file, bad JSON, or unknown keys all fall back to defaults —
the config can never break a run.

```json
{
  "display": {
    "color": true,
    "header": "cyan",
    "language": "green",
    "total": "cyan",
    "languages": {
      "Rust": "#ff5500",
      "Python": "255,165,0"
    }
  },
  "languages": {
    "MyLang": {
      "extensions": ["myl"],
      "files": ["Myfile"],
      "line": ["#"],
      "block_start": ["/*"],
      "block_end": ["*/"]
    }
  }
}
```

### Colors (`display`)

| Key | What it paints | Default |
|-----|----------------|---------|
| `header` | table header row | `cyan` |
| `language` | language names | `green` |
| `total` | total row | `cyan` |
| `languages` | per-language overrides | — |
| `color` | master switch (`false` = plain) | `true` |

A hue is a color **name** (`black red green yellow blue magenta
cyan white` and `bright_*`), **hex** (`"#ff5500"`, `"#f50"`), or
**RGB** (`"255,165,0"`). Unknown hues render plain, never an error.

Rules: per-language wins; `Markdown`/`Text` stay plain unless you
override them explicitly; the Markdown section rows are dimmed and
follow overrides, else the default language hue. Bold stays as-is.

### Custom languages (`languages`)

Each entry **replaces** the whole builtin entry of the same name:

| Field | Meaning |
|-------|---------|
| `extensions` | counted file extensions, no dot |
| `files` | counted exact filenames (`Makefile`, `.bashrc`) |
| `line` | line-comment markers |
| `block_start` / `block_end` | block-comment pair (single-element arrays) |

Comment rules apply to **new** languages. Builtin languages keep
their built-in rules (stable counts); use `extensions`/`files` to
re-point an existing language at new files.

Precedence: builtin `languages.json` < `~/.config/zcc/languages.json`
< `config.json` → `languages` (later wins per language name).

## Top files and generated code

`--by-file` appends a top-N section (and a `files` array to JSON).
Files matching generated patterns (bundles, lockfiles, protobuf,
codegen, `generated/` trees) aggregate under a `Generated` row,
never into language totals.

## Count cache

Warm runs skip all file IO: `~/.cache/zcc/<slug(root)>.json` stores
per-file mtime + size + counts. Any edit, new, or deleted file
recounts automatically (only that file). Filtered views (`--only`,
`--hidden`, `--no-ignore`) read the cache but never write it, so a
partial run can't poison full runs. `--no-cache` forces a full recount.

## How files are chosen

`walk → .gitignore/.ignore/.zccignore → default skips`. Always
skipped: `.git/.hg/.svn`, `target`, `node_modules`, `vendor`, `bin`,
`build`, `__pycache__`, `.idea/.vscode`. Binary detection: strict
UTF-8 read + NUL scan (single read per file).

## Markdown fences

Fenced code blocks count toward the parent Markdown row (as comments,
like tokei) and get their own aligned section after the table:

```
Total                532    143527    115383     18260      9884
────────────────────────────────────────────────────────────────

 Markdown (embedded code)
 BASH                 27       186       159         0        27
 ...
 └ (Total)            44       479       382        34        63
```

## Performance

Warm cache + pruning walk: ~70ms on a 500-file tree (beats tokei;
startup floor is ~35ms). Cold recount is I/O-bound at roughly
1s per 250k lines. `--no-cache` numbers are the honest cold metric.
