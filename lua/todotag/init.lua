local Config = require("todotag.config")
local Highlight = require("todotag.highlight")


local M = {}

M.setup = Config.setup
M.attach = Highlight.attach
M.start = Highlight.start
M.stop = Highlight.stop

-- Register user commands
vim.api.nvim_create_user_command("TodotagStart", M.start, { desc = "Start todotag.nvim highlighting" })

vim.api.nvim_create_user_command("TodotagStop", M.stop, { desc = "Stop todotag.nvim highlighting" })

return M
