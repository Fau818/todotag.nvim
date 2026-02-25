# ✅ todotag.nvim
A lightweight and customizable Neovim plugin that highlights todo tags in comments.

## ✨ Features
- **Customizable Todo Tags**: Define your own todo keywords and highlight groups
- **Smart Highlighting**: Only highlights tags in comment regions (treesitter + syntax fallback)
- **Partial Highlighting**: Match a broader pattern but only highlight a portion (e.g., match `todo:` but highlight `todo`)
- **Case Sensitivity**: Control whether tags are case-sensitive
- **Performance**: Efficiently highlights only visible regions with throttling

## 🎨 Demo
### Basic Showcase
![Basic Showcase](assets/showcase.png)

### With todo-comments.nvim Integration
![With todo-comments.nvim](assets/showcase_with_todocomments.png)

## 📦 Installation
```lua
-- lazy.nvim
{
  "fau818/todotag.nvim",
  dependencies = "folke/todo-comments.nvim",  -- Optional
  opts = {},
}
```

## 🚀 Usage
The plugin starts automatically after `setup()`. You can also control it manually:

```vim
:TodotagStart  " Start highlighting todo tags
:TodotagStop   " Stop highlighting todo tags
```

## ⚙️ Configuration
Full configuration example with all options:
```lua
require("todotag").setup({
  -- Keywords recognized as todo tags
  keywords = {
    { pattern = "todo:", hl_part = "todo", hl_group = "Todo", case_sensitive = false },
    { pattern = "[todo]", hl_part = "todo", hl_group = "Todo", case_sensitive = false },
    { pattern = "fix",   hl_group = "Error", case_sensitive = true },
    { pattern = "note:", hl_part = "note", hl_group = "DiagnosticInfo", case_sensitive = false },
  },

  -- Highlight priority (default: 501, covers todo-comments.nvim)
  priority = 501,

  -- Throttle updates (in ms, default: 250)
  throttle = 250,

  -- Only highlight in visible area (default: true)
  only_visible = true,

  -- Exclude these filetypes
  exclude_ft = { "help", "netrw", "tutor" },

  -- Exclude these buftypes
  exclude_bt = { "nofile", "prompt" },
})
```

### Keyword Options
| Field | Type | Description |
|---|---|---|
| `pattern` | `string` | **Required.** The string to match in comments. |
| `hl_group` | `string` | **Required.** Highlight group to apply. |
| `hl_part` | `string?` | Substring of `pattern` to highlight. If omitted, the entire match is highlighted. |
| `case_sensitive` | `boolean?` | Default `false`. When `false`, matches regardless of case. |

## 📖 Example Configuration
```lua
return {
  "fau818/todotag.nvim",

  opts = {
    keywords = {
      { pattern = "todo:", hl_part = "todo", hl_group = "TodoTag", case_sensitive = false },
      { pattern = "note:", hl_part = "note", hl_group = "InfoTag", case_sensitive = false },
      { pattern = "fix", hl_group = "FixTag", case_sensitive = false },
    },
  },

  config = function(_, opts)
    -- Define custom highlight groups with literal colors
    vim.api.nvim_set_hl(0, "TodoTag", { fg = "#39CC8F", bold = true, italic = true })
    vim.api.nvim_set_hl(0, "InfoTag", { fg = "#7AA2F7", bold = true, italic = true })
    vim.api.nvim_set_hl(0, "FixTag",  { fg = "#C53B53", bold = true, italic = true })

    require("todotag").setup(opts)
  end,
}
```

## ❗️ Troubleshooting
### Tags Are Not Highlighted
1. Ensure the tag is inside a comment
2. Check that the filetype is not excluded
3. Verify the buftype is not excluded
4. Make sure the plugin is started with `:TodotagStart`

### Performance Issues
- Increase `throttle` to reduce update frequency
- Set `only_visible = true` to only highlight visible lines
- Reduce the number of keywords

## 📄 License
MIT License - see [LICENSE](LICENSE) file for details

## 💬 Support
If you have any questions or issues, please open an issue on the GitHub repository: [issues](https://github.com/fau818/todotag.nvim/issues)

## 🙏 Acknowledgments
- Inspired by various todo highlighting plugins
- Uses ideas from [folke/todo-comments.nvim](https://github.com/folke/todo-comments.nvim)
