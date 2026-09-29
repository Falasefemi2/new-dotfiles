# FEMMIE Keymaps

> Leader key: `<Space>`

---

## General

| Keymap | Mode | Description |
|--------|------|-------------|
| `<Esc>` | n | Clear search highlights |
| `<leader>q` | n | Open diagnostic quickfix list |

## Window Navigation

| Keymap | Mode | Description |
|--------|------|-------------|
| `<C-h>` | n | Move focus to the left window |
| `<C-l>` | n | Move focus to the right window |
| `<C-j>` | n | Move focus to the lower window |
| `<C-k>` | n | Move focus to the upper window |
| `<C-Up>` | n | Increase window height |
| `<C-Down>` | n | Decrease window height |
| `<C-Left>` | n | Decrease window width |
| `<C-Right>` | n | Increase window width |

## Buffers

| Keymap | Mode | Description |
|--------|------|-------------|
| `[b` | n | Previous buffer |
| `]b` | n | Next buffer |
| `<leader>bd` | n | Delete buffer (with save prompt) |
| `<leader>,` | n | Find open buffers (Telescope) |

## Search (Telescope)

| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>sh` | n | Search help tags |
| `<leader>sk` | n | Search keymaps |
| `<leader>sf` | n | Search files |
| `<leader>ss` | n | Select Telescope picker |
| `<leader>sw` | n, v | Search current word |
| `<leader>sg` | n | Live grep |
| `<leader>sd` | n | Search diagnostics |
| `<leader>sr` | n | Resume last search |
| `<leader>s.` | n | Search recent files |
| `<leader>sc` | n | Search commands |
| `<leader>sn` | n | Search Neovim config files |
| `<leader>/` | n | Fuzzily search in current buffer |
| `<leader>s/` | n | Live grep in open files |

## LSP

| Keymap | Mode | Description |
|--------|------|-------------|
| `grn` | n | LSP rename |
| `gra` | n, x | LSP code action |
| `grD` | n | LSP goto declaration |
| `grr` | n | LSP references |
| `gri` | n | LSP goto implementation |
| `grd` | n | LSP goto definition |
| `gO` | n | Open document symbols |
| `gW` | n | Open workspace symbols |
| `grt` | n | LSP goto type definition |
| `<leader>th` | n | Toggle inlay hints |
| `<leader>cl` | n | Run code lens |

## Git (Gitsigns)

| Keymap | Mode | Description |
|--------|------|-------------|
| `]c` | n | Jump to next git change |
| `[c` | n | Jump to previous git change |
| `<leader>hs` | n, v | Stage hunk |
| `<leader>hr` | n, v | Reset hunk |
| `<leader>hS` | n | Stage buffer |
| `<leader>hR` | n | Reset buffer |
| `<leader>hp` | n | Preview hunk |
| `<leader>hi` | n | Preview hunk inline |
| `<leader>hb` | n | Blame line (full) |
| `<leader>hd` | n | Diff against index |
| `<leader>hD` | n | Diff against last commit |
| `<leader>hQ` | n | Quickfix list (all files in repo) |
| `<leader>hq` | n | Quickfix list (changes in file) |
| `<leader>tb` | n | Toggle inline blame |
| `<leader>tw` | n | Toggle word diff |

## Git (Neogit)

| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>gg` | n | Open Neogit UI |

## File Explorer (Neo-tree)

| Keymap | Mode | Description |
|--------|------|-------------|
| `\` | n | Reveal current file in Neo-tree |
| `\` (in Neo-tree) | n | Close Neo-tree window |

## Formatting

| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>f` | n, v | Format buffer |

## Search & Replace (Spectre)

| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>rp` | n | Replace in project |
| `<leader>rP` | n | Replace project word under cursor |
| `<leader>rf` | n | Replace in current file |
| `<leader>rr` | n, x | Replace word/selection under cursor |

## Trouble (Diagnostics)

| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>xx` | n | Toggle diagnostics panel |
| `<leader>xX` | n | Toggle buffer diagnostics |
| `<leader>cs` | n | Toggle symbols panel |
| `<leader>cr` | n | Toggle LSP references panel |
| `<leader>xL` | n | Toggle location list |
| `<leader>xQ` | n | Toggle quickfix list |

## Terminal (Toggleterm)

| Keymap | Mode | Description |
|--------|------|-------------|
| `<C-\\>` | n, t | Toggle terminal |
| `<leader>tt` | n | Toggle terminal |
| `<leader>tn` | n | New terminal |
| `<leader>ts` | n | Select terminal |
| `<leader>t]` | n | Next terminal |
| `<leader>t[` | n | Previous terminal |
| `<leader>tq` | n | Close terminal |
| `<leader>t1`–`<leader>t9` | n | Toggle terminal 1–9 |

## Go (only in .go files)

| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>gt` | n | Run `go test ./...` |
| `<leader>gT` | n | Run `go test -v ./...` |
| `<leader>gr` | n | Run `go run .` |
| `<leader>gm` | n | Run `go mod tidy` |
| `<leader>gv` | n | Run `go vet ./...` |
| `<leader>ga` | n | Toggle test/impl file |

## Folds (nvim-ufo)

| Keymap | Mode | Description |
|--------|------|-------------|
| `zR` | n | Open all folds |
| `zM` | n | Close all folds |
| `zK` | n | Peek inside fold |

## Session

| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>Ss` | n | Save session |
| `<leader>Sl` | n | Load session |
| `<leader>SS` | n | Select session (picker) |
| `<leader>Sd` | n | Stop session persistence |

## Markdown Preview

| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>mp` | n | Toggle markdown preview in browser |

## Flash (Jump) + Surround

| Keymap | Mode | Description |
|--------|------|-------------|
| `s` | n, x, o | Flash jump (overrides built-in substitute; use `cl` instead) |
| `gsa` / `gsd` / `gsr` | n, x | Surround add / delete / replace (mini.surround lives under `gs` so `s` stays Flash) |

## Debug (DAP) - Go / Python / TS/JS (delve / debugpy / js-debug)

| Keymap | Mode | Description |
|--------|------|-------------|
| `<F5>` | n | Start/Continue |
| `<F1>` | n | Step into |
| `<F2>` | n | Step over |
| `<F3>` | n | Step out |
| `<F6>` | n | Terminate |
| `<F7>` | n | Toggle DAP UI (last session) |
| `<leader>db` | n | Toggle breakpoint |
| `<leader>dB` | n | Conditional breakpoint (input) |
| `<leader>dl` | n | Log point (input) |
| `<leader>dr` | n | Open REPL |
| `<leader>du` | n | Toggle DAP UI |
| `<leader>de` | n, v | Evaluate expression (visual) |

## Utility Windows

| Keymap | Mode | Description |
|--------|------|-------------|
| `q` | n | Close help/man/notify/quickfix windows (terminal excluded) |
| `<Esc><Esc>` | t | Exit terminal mode |

## TypeScript / JavaScript (Effect + fallback)

| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>co` | n | Organize imports (TS/JS buffer) |
| `<leader>cT` | n | Run `npm test` in split terminal |
| `<leader>ce` | n | Show TS error (ts_ls buffers; diagnostic float in Effect projects) |
| `<leader>cE` | n | Show all TS errors |
| `<leader>ct` | n | Toggle TS error auto-display |

## REPL (iron.nvim) — `<leader>e` = [E]xecute

> Upstream iron docs use `<space>r` / `<space>s`, but here `<leader>r` is Spectre replace and `<leader>s` is Telescope search, so iron lives under `<leader>e`.

| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>et` | n | Toggle REPL open/closed |
| `<leader>eR` | n | Restart REPL (`:IronRestart`) |
| `<leader>ef` | n | Focus REPL (`:IronFocus`) |
| `<leader>eh` | n | Hide REPL (`:IronHide`) |
| `<leader>es` | n, x | Send motion / visual selection to REPL |
| `<leader>el` | n | Send line to REPL |
| `<leader>ep` | n | Send paragraph to REPL |
| `<leader>eF` | n | Send whole file to REPL |
| `<leader>eu` | n | Send until cursor to REPL |
| `<leader>eb` | n | Send code block (`# %%` aware in Python) |
| `<leader>en` | n | Send code block and move to next |
| `<leader>eM` | n | Send marked text to REPL |
| `<leader>em` | n, x | Mark motion / visual region for REPL |
| `<leader>eD` | n | Remove REPL mark |
| `<leader>e<CR>` | n | Send `<CR>` to REPL |
| `<leader>e<Space>` | n | Interrupt REPL (Ctrl-C) |
| `<leader>eq` | n | Exit/close REPL |
| `<leader>eC` | n | Clear REPL screen |

REPLs configured: `sh` (zsh / `$SHELL`, PowerShell on Windows), `powershell`, `python` (project `.venv` aware, `PYTHON_BASIC_REPL=1` for 3.13+), `lua`, `javascript` (node), `typescript` (ts-node). Opens with `view.bottom(40)`. Sends go to nvim-dap REPL when debugging.

## LaTeX (only in .tex/.bib files)

| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>ll` | n | Compile (toggle continuous) |
| `<leader>lv` | n | View PDF |
| `<leader>ls` | n | Forward search (sync) |
| `<leader>lf` | n | Forward search (texlab) |
| `<leader>lb` | n | Build once (texlab) |
| `<leader>le` | n | Errors/quickfix |
| `<leader>lc` | n | Clean aux files |
| `<leader>lk` | n | Stop compiler |
| `<leader>lK` | n | Stop all compilers |
| `<leader>lt` | n | Toggle ToC |
| `<leader>li` | n | Info/state |
| `<leader>lr` | n | Reload state |

### LaTeX Snippets (LuaSnip, `tex` filetype)

`doc` document skeleton · `beg` begin/end env (mirrored) · `mk` inline math · `dm` display math · `eq` labeled equation · `frac` fraction · `fig` figure · `tbl` table · `item` itemize · `enum` enumerate · `sec`/`sub`/`subsub` sections · `pkg` usepackage · `cite`/`ref`/`lab` cross-refs · `tbf`/`tit` bold/italic · `href` hyperlink. Complete via blink.cmp, jump with `<tab>`/`<s-tab>`.

---

*Generated from your Neovim config — 95+ keymaps across all plugins.*
