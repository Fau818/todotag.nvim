local M = {}


---@type Todotag.Config
local DEFAULTS = {
  -- Keywords recognized as todo tags
  keywords = { todo = { hl_group = "Todo", case_sensitive = false } },
  priority = 501,  -- Cover todo-comments.nvim priority, which is 500 by default.

  throttle = 250,
  only_visible = true,  -- Only show todo tags in the visible area

  exclude_ft = { "help", "netrw", "tutor" },
  exclude_bt = { "nofile", "prompt" },
}

M.config = DEFAULTS


function M.setup(user_config)
  M.config = vim.tbl_deep_extend("force", M.config, user_config or {})
  vim.schedule(function() require("todotag.highlight").start() end)
end


return M
