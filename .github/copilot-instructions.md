# Copilot Instructions for todotag.nvim

## About

todotag.nvim is a Neovim plugin (Lua) that highlights todo-tag keywords inside comment regions. It uses treesitter (with syntax highlighting fallback) for comment detection and integrates with [todo-comments.nvim](https://github.com/folke/todo-comments.nvim) by avoiding overlap with its `TodoBg*` extmarks.

## Architecture

All plugin code lives in `lua/todotag/`:

- **`init.lua`** — Entry point. Exposes `setup()`, `start()`, `stop()`, `attach()` and registers `:TodotagStart`/`:TodotagStop` user commands.
- **`config.lua`** — Holds `DEFAULTS` and merges user config via `vim.tbl_deep_extend`. Calling `setup()` stores the merged config in `M.config` and schedules `highlight.start()`.
- **`highlight.lua`** — Core logic: buffer attach/detach, per-buffer state tracking (valid line map), pattern matching, throttled updates via `vim.uv` timer, and extmark management under the `todotag.nvim` namespace.
- **`_meta.lua`** — LuaCATS type definitions only (no runtime code).

## Key Conventions

- **Module pattern**: Every file returns a local table `M` with all public functions/state as fields.
- **Type annotations**: Use LuaCATS annotations (`---@class`, `---@field`, `---@param`, `---@return`, `---@type`). Type-only definitions go in `_meta.lua`.
- **Line indexing**: The plugin's public/internal API uses **1-indexed** line numbers. Convert to 0-indexed only at the Neovim API boundary (`nvim_buf_get_lines`, `nvim_buf_set_extmark`, etc.). Comments in the code mark which indexing is used.
- **Keywords config**: `keywords` is an **array** of keyword option tables (not a dict). Each entry has a required `pattern` field and optional `hl_part`, `hl_group`, `case_sensitive`.
- **Word boundary matching**: Frontier patterns (`%f`) are applied conditionally — only at pattern edges where the character is a word character (`%w`, `_`, `-`).
- **Partial highlighting**: Keywords support `pattern` (full match string) and `hl_part` (substring to highlight). If `hl_part` is omitted, the entire match is highlighted.
