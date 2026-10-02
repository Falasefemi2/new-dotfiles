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
  noice.lua, toggleterm, trouble, ufo, dashboard...
.luarc.json              # LuaLS config for Neovim
.stylua.toml             # 160 cols, 2 spaces
nvim-pack-lock.json      # Tracked for reproducible installs
```

## Plugins (vim.pack)

| Area | Plugins |
|------|---------|
| Core | `guess-indent`, `which-key`, `todo-comments`, `mini.ai/surround/bufremove` |
| UI | `catppuccin`, `lualine`, `dashboard-nvim`, `noice`, `nvim-notify`, `smear-cursor`, `statuscolumn`, `colorizer` |
| Nav | `telescope`, `neo-tree`, `flash` |
| LSP | `nvim-lspconfig`, `mason`, `mason-tool-installer`, `fidget`, `conform`, `blink.cmp`, `LuaSnip` |
| Treesitter | `nvim-treesitter:main`, `nvim-ts-autotag` |
| Git | `gitsigns`, `neogit`, `diffview` |
| Lang | `gopls`, `pyright/ruff`, `ts_ls` + `effect_tsgo`, `tailwindcss`, `lua_ls` |
| Debug | `nvim-dap`, `dap-ui`, `mason-nvim-dap`, `nvim-dap-go` |
| Custom | `persistence`, `toggleterm`, `trouble`, `nvim-spectre`, `ufo`, `wakatime` |

Run `:lua vim.pack.update(nil, {offline=true})` to inspect, `:lua vim.pack.update()` to update.

## Keymaps

Leader is `<Space>`. See `keymapp.md` for full table (95+ maps) or `:Telescope keymaps`.

Notables: `\- Neotree reveal`, `<leader>,` buffers, `<leader>sf/sg/` Telescope, `gr*` LSP, `<leader>db/dB` DAP breakpoint, `<leader>Ss/Sl` session, `<leader>mp` markdown preview, `s` flash jump.

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
