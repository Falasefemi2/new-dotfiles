# FEMMIE Nvim — Senior Kickstart Fork

> Personal Neovim config built on `nvim-lua/kickstart.nvim`, hardened for Go, TypeScript (Effect), Python, and daily work on Windows + Linux. Modular, reproducible (`vim.pack` + lockfile), and `stylua` clean.

**Targets:** Neovim 0.11+ (stable/nightly), `vim.pack` (built-in plugin manager, no lazy.nvim).

## Structure

```
init.lua                 # ~1100 lines: bootstrap + plugin sections (vim.pack)
lua/config/
  options.lua            # vim.o, diagnostics, undo
  keymaps.lua            # core <leader> maps (no plugin deps)
  autocmds.lua           # yank-hl, auto-mkdir, VimResized, q-close
lua/kickstart/plugins/   # Kickstart core (gitsigns, lint, debug, neo-tree...)
lua/custom/plugins/      # FEMMIE layer (explicit manifest in init.lua)
  session.lua            # persistence.nvim with neo-tree fix (E95)
  effect-tsgo.lua        # @effect/tsgo binary LSP (tsgo fork)
  go.lua                 # gopls imports + test toggles
  lualine.lua            # statusline (single source of truth)
  noice.lua, trouble, ufo, dashboard...
.luarc.json              # LuaLS config for Neovim
.stylua.toml             # 160 cols, 2 spaces
nvim-pack-lock.json      # Tracked for reproducible installs
```

## Plugins (vim.pack)

| Area | Plugins |
|------|---------|
| Core | `guess-indent`, `which-key`, `todo-comments`, `mini.ai/surround/bufremove` |
| UI | `catppuccin`, `lualine`, `dashboard-nvim`, `noice`, `nvim-notify`, `smear-cursor`, `statuscolumn`, `colorizer` |
| Nav | `telescope`, `neo-tree`, `flash`, `harpoon` |
| LSP | `nvim-lspconfig`, `mason`, `mason-tool-installer`, `fidget`, `conform`, `blink.cmp`, `LuaSnip` |
| Treesitter | `nvim-treesitter:main`, `nvim-ts-autotag` |
| Git | `gitsigns`, `neogit`, `diffview` |
| Lang | `gopls`, `pyright/ruff`, `ts_ls` + `effect_tsgo`, `tailwindcss`, `lua_ls` |
| Debug | `nvim-dap`, `dap-ui`, `mason-nvim-dap`, `nvim-dap-go` |
| Custom | `persistence`, `trouble`, `nvim-spectre`, `ufo`, `wakatime`; dependency-free floats in `lua/custom/floatterm.lua` |

Run `:lua vim.pack.update(nil, {offline=true})` to inspect, `:lua vim.pack.update()` to update.

## Keymaps

Leader is `<Space>`. See `keymapp.md` for full table (95+ maps) or `:Telescope keymaps`.

Notables: `\- Neotree reveal`, `<leader>,` buffers, `<leader>sf/sg/` Telescope, `gr*` LSP, `<leader>db/dB` DAP breakpoint, `<leader>Ss/Sl` session, `<leader>mp` markdown preview, `s` flash jump.

## Harpoon - Neovim File Navigation

[Harpoon 2](https://github.com/ThePrimeagen/harpoon) pins a small set of files you keep returning to and lets you jump to them with one keystroke. Instead of reopening a fuzzy finder or cycling through buffers, you mark the files that matter for the current project once and then move between them directly. The list is scoped to the git repository root (falling back to the working directory outside a repo), so it is still available the next time you start Neovim anywhere inside that project.

### Add files

Open a file and press `<leader>ha` to add the current buffer to the Harpoon list. Press it again on other files to append them in the order you want to reach them.

### Open the quick menu

Press `<leader>hh` to toggle the Harpoon quick menu. The menu lists every saved file with a line number and highlights the file you are currently editing. Inside the menu:

- `<CR>` opens the file under the cursor.
- `<C-v>` opens it in a vertical split.
- `<C-x>` opens it in a horizontal split.
- `<C-t>` opens it in a new tab.
- `q` or `<Esc>` closes the menu.
- `dd` deletes the entry under the cursor. Closing the menu saves the change.

### Jump to saved files

Use the numbered mappings to go straight to a slot:

- `<leader>1` — first saved file
- `<leader>2` — second saved file
- `<leader>3` — third saved file
- `<leader>4` — fourth saved file

### Move between saved files

- `<leader>hn` — next saved file
- `<leader>hP` — previous saved file

> `<leader>hp` is already used by gitsigns to preview the hunk under the cursor, so Harpoon's previous-file mapping uses the uppercase variant `<leader>hP`. Next/previous wrap around at the ends of the list.

### Fuzzy-find saved files

Press `<leader>hT` to open the Harpoon list in Telescope. This is useful when the list grows beyond the four numbered slots: you get fuzzy filtering and a file preview while keeping the same Harpoon list.

### Remove files from Harpoon

For the current file, press `<leader>hx` to remove it immediately. To remove any other file, open the menu with `<leader>hh`, put the cursor on its line, delete the line with `dd`, then close the menu with `q` or `<Esc>`. The list is saved automatically. (`<CR>` on another entry or `:w` also applies the change.)

### Keybinding reference

| Keybinding | Action | Description |
|------------|--------|-------------|
| `<leader>ha` | Add file | Add the current buffer to the Harpoon list |
| `<leader>hh` | Toggle menu | Open or close the Harpoon quick menu |
| `<leader>1` | Select file 1 | Jump to the first saved file |
| `<leader>2` | Select file 2 | Jump to the second saved file |
| `<leader>3` | Select file 3 | Jump to the third saved file |
| `<leader>4` | Select file 4 | Jump to the fourth saved file |
| `<leader>hn` | Next file | Jump to the next saved file (wraps) |
| `<leader>hP` | Previous file | Jump to the previous saved file (wraps; `<leader>hp` is gitsigns preview hunk) |
| `<leader>hx` | Remove file | Remove the current file from the Harpoon list |
| `<leader>hT` | Telescope | Fuzzy-find the saved files with preview |

Menu-local keys: `<CR>` open the entry under the cursor, `<C-v>` / `<C-x>` / `<C-t>` open it in a vertical split / horizontal split / new tab, `q` / `<Esc>` close the menu, `dd` delete an entry (saved when the menu closes).

### Typical Go workflow

Say you are working on a Go service and keep moving between `main.go`, `handler.go`, and `store.go`.

1. Open `main.go` and press `<leader>ha`. It becomes slot 1.
2. Open `handler.go` and press `<leader>ha`. It becomes slot 2.
3. Open `store.go` and press `<leader>ha`. It becomes slot 3.
4. Press `<leader>hh` to see the three files in the quick menu.
5. Press `<leader>1` to jump back to `main.go`, `<leader>2` for `handler.go`, or `<leader>3` for `store.go`.
6. Use `<leader>hn` and `<leader>hP` to move through the list without remembering slot numbers.
7. To drop `store.go`, press `<leader>hh`, move to its line, press `dd`, then close the menu with `q`.
8. If you want to fuzzy-find among the saved files instead, press `<leader>hT`.

Because the list is scoped to the git repository root, starting Neovim anywhere inside the repo restores the same set of files on the next session.

## Session Fix (this repo)

`folke/persistence.nvim` + `neo-tree.nvim` leaked `badd neo-tree filesystem [1]` into `vim-data/session/*.vim` causing:

```
E95: Buffer with this name already exists (renderer.lua:1228)
Invalid 'window': Expected Lua number (nui/tree)
```

Fixed in `lua/custom/plugins/session.lua:11` `pre_save` closes/wipes neo-tree and drops `winpos` from `options`, plus `VimEnter` uses `nested=true` + `vim.schedule`.

## Install

```sh
git clone https://github.com/Falasefemi2/new-dotfiles.git ~/.config/nvim  # Linux
# Windows: git clone https://github.com/Falasefemi2/new-dotfiles.git %localappdata%\nvim
nvim # vim.pack installs on first start
:Mason # verify LSPs
```

Dependencies: `git`, `make`/`gcc`, `ripgrep`, `fd`, `node`/`npm` (for markdown-preview, biome/prettier), `go`.

## Health & Formatting

```sh
nvim --headless -c "checkhealth" -c "qa"
stylua --check .
```

CI: `.github/workflows/stylua.yml` runs on push/PR to `femmie-branch`.

## Docs

- `keymapp.md` — generated keymap reference
- `:help vim.pack`, `:help lsp`, `:Telescope help_tags`
- Original Kickstart docs archived in `doc/` (if kept)

## License

Same as kickstart.nvim (MIT).
