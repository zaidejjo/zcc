```
███████   █████   █████
     ██  ██   ██ ██   ██
    ██   ██      ██
   ██    ██      ██
  ██     ██      ██
 ██      ██   ██ ██   ██
███████   █████   █████
```

[![ci](https://github.com/zaidejjo/zcc/actions/workflows/ci.yml/badge.svg)](https://github.com/zaidejjo/zcc/actions)
[![release](https://img.shields.io/github/v/release/zaidejjo/zcc)](https://github.com/zaidejjo/zcc/releases)
[![aur](https://img.shields.io/aur/version/zcc)](https://aur.archlinux.org/packages/zcc)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![arch](https://img.shields.io/badge/arch-x86__64-lightgrey.svg)]()

**The blazing-fast code counter** — 70+ languages, Markdown fence breakdowns,
JSON output, and warm runs under 0.1s. A tokei clone written in ZZ.

> *"Blink and it's counted."*

---

```
$ zcc
────────────────────────────────────────────────────────────────
Language           Files     Lines      Code  Comments    Blanks
────────────────────────────────────────────────────────────────
Rust                 242    115221     95434     12724      7063
ZZ                   235      7816      5818      1102       896
Markdown              17      4176      1133      2146       897
────────────────────────────────────────────────────────────────
Total                538    143995    115691     18385      9923
────────────────────────────────────────────────────────────────

 Markdown (embedded code)
 BASH                 27       186       159         0        27
 Rust                  9       209       153        30        26
 └ (Total)            44       479       382        34        63
```

## Highlights

- **Fast** — ~70ms warm on a 500-file tree (beats tokei); ~300ms cold recount
- **Smart Markdown** — fenced code blocks attributed to their language
- **Custom languages** — add your own via config, with comment rules
- **Themable** — named, hex, or RGB colors globally and per language
- **Honest JSON** — machine-readable output for scripts and CI
- **Generated-aware** — bundles, lockfiles and codegen don't pollute totals
- **Cached** — mtime-keyed counts, instant repeat runs

## Install

**Arch Linux (AUR):**
```sh
yay -S zcc
```

**Prebuilt binary** (Linux x86_64) — from the
[releases page](https://github.com/zaidejjo/zcc/releases):
```sh
tar -xzf zcc-0.1.0-linux-x86_64.tar.gz
sudo install -Dm755 zcc /usr/bin/zcc
```

**From source** (needs the [ZZ toolchain](https://github.com/zaidejjo/zz)):
```sh
git clone https://github.com/zaidejjo/zcc.git && cd zcc
cargo install --path ~/zz/crates/zz_cli   # the ZZ compiler
zz build -p src/main.zz
sudo cp src/bin/main /usr/bin/zcc
```

## Usage

```sh
zcc [path] [flags]
zcc init [--force]
```

| Flag | Effect |
|------|--------|
| `--output json` | machine-readable JSON on stdout |
| `--only LANG` | count one language (`--only Rust`) |
| `--by-file` | list top files by lines after the table |
| `--top N` | files shown with `--by-file` (default 20) |
| `--hidden` | include hidden files/dirs |
| `--no-ignore` | skip `.gitignore` rules (still skips `.git`) |
| `--no-cache` | always recount, don't read/write the cache |
| `--force` | with `init`: overwrite existing config |
| `--help`, `--version` | |

```sh
zcc .                              # this tree
zcc src/ --only Rust               # one language
zcc . --output json > counts.json  # scripts love this
zcc --by-file --top 10             # where is all that code?
zcc init                           # scaffold ~/.config/zcc/config.json
```

`NO_COLOR=1` disables all color.

## Configuration

All customization lives in `~/.config/zcc/config.json`
(`%APPDATA%\zcc\config.json` on Windows). Scaffold it with `zcc init`,
steal ideas from `config.example.json`, or theme it like
`config.example-zz.json`. Missing file, bad JSON, or unknown keys all
fall back to defaults — the config can never break a run.

```json
{
  "display": {
    "color": true,
    "header": "cyan",
    "language": "green",
    "total": "cyan",
    "languages": {
      "ZZ": "#1e8ffb",
      "Rust": "#ff5500"
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
like tokei) and get their own aligned section after the table (see
the demo above).

## Performance

| Run | zz_lang tree (538 files) |
|-----|--------------------------|
| Warm cache | **~70ms** |
| Cold recount | ~300ms |
| `tokei` (warm) | ~88ms |
| `scc` (warm) | ~59ms |

Warm cache + pruning walk; startup floor is ~35ms. `--no-cache`
numbers are the honest cold metric.

## License

MIT — see [LICENSE](LICENSE).
