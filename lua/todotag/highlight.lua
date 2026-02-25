local Config = require("todotag.config")

local M = {}

M.enabled = false  -- Plugin enabled state

M.bufs = {} ---@type table<number, boolean>
M.wins = {} ---@type table<number, boolean>

M.ns = vim.api.nvim_create_namespace("todotag.nvim")
M.autocmd_group = nil


-- ==================== State ====================
M.state = {}  ---@type table<number, {valid: table<number, boolean>}>

function M.get_state(bufnr)
  if not M.state[bufnr] then M.state[bufnr] = { valid = {} } end
  return M.state[bufnr]
end


---@param bufnr number Buffer number
---@param first number First line (1-indexed)
---@param last number Last line (1-indexed)
---Invalidate lines in the buffer from first to last (inclusive).
function M.invalidate(bufnr, first, last)
  local state = M.get_state(bufnr)
  if first > last then state.valid = {}
  else for i = first, last do state.valid[i] = false end
  end
  M.update()
end


-- ==================== Pattern ====================
local _patterns = nil  ---@type Todotag.Patterns

---Build a search pattern with frontier assertions at word-character edges.
---Frontiers are only applied where the edge character is a word char (%w, _, -).
---@param escaped string The vim.pesc-escaped pattern string.
---@param raw string The original (unescaped) pattern string.
---@return string
local function build_pattern_with_frontiers(escaped, raw)
  local first_char = raw:sub(1, 1)
  local last_char = raw:sub(-1)
  local leading = first_char:match("[%w_%-]") and "%f[%w_-]" or ""
  local trailing = last_char:match("[%w_%-]") and "%f[^%w_-]" or ""
  return leading .. escaped .. trailing
end


---Get the todo-tag patterns based on the configuration.
---@return Todotag.Patterns[]
local function get_patterns()
  if _patterns == nil then
    _patterns = {}
    for _, opts in ipairs(Config.config.keywords) do
      local raw_pattern = opts.pattern
      local escaped_pattern = vim.pesc(raw_pattern)
      -- For case-insensitive matching, use lowercase pattern.
      if not opts.case_sensitive then
        raw_pattern = raw_pattern:lower()
        escaped_pattern = escaped_pattern:lower()
      end

      local search_pattern = build_pattern_with_frontiers(escaped_pattern, raw_pattern)

      -- Compute highlight offset/length when hl_part is specified
      local hl_offset, hl_len
      if opts.hl_part then
        local hl_str = opts.case_sensitive and opts.hl_part or opts.hl_part:lower()
        local match_str = raw_pattern
        local pos = match_str:find(hl_str, 1, true)
        if pos then hl_offset, hl_len = pos, #hl_str
        else
          vim.notify(
            ("[todotag.nvim] hl_part `%q` not found in pattern `%q`, highlighting full match"):format(opts.hl_part, opts.pattern),
            vim.log.levels.WARN,
            { title = "todotag.nvim" }
          )
        end
      end

      _patterns[#_patterns+1] = {
        pattern = search_pattern,
        hl_group = opts.hl_group,
        case_sensitive = opts.case_sensitive,
        hl_offset = hl_offset,
        hl_len = hl_len,
      }
    end
  end
  return _patterns
end


-- ==================== Highlight ====================
local todo_comments_ns = nil

-- REF: https://github.com/folke/todo-comments.nvim/blob/31e3c38ce9b29781e4422fc0322eb0a21f4e8668/lua/todo-comments/highlight.lua#L63
---Check if a position is inside a comment. (0-indexed)
---@param bufnr number Buffer number.
---@param row number 0-indexed row.
---@param col number 0-indexed column.
---@return boolean
local function is_comment(bufnr, row, col)
  if vim.treesitter.highlighter.active[bufnr] then
    local captures = vim.treesitter.get_captures_at_pos(bufnr, row, col)
    for _, c in ipairs(captures) do
      if c.capture == "comment" then return true end
    end
  else
    local win = vim.fn.bufwinid(bufnr)
    return win ~= -1 and vim.api.nvim_win_call(win, function()
      for _, i1 in ipairs(vim.fn.synstack(row + 1, col)) do
        local i2 = vim.fn.synIDtrans(i1)
        local n1 = vim.fn.synIDattr(i1, "name")
        local n2 = vim.fn.synIDattr(i2, "name")
        if n1 == "Comment" or n2 == "Comment" then return true end
      end
    end)
  end
  return false
end


---Check if a region has existing TodoBg* extmarks. (0-indexed)
---@param bufnr number Buffer number.
---@param line number 0-indexed line number.
---@param scol number 0-indexed start column.
---@param ecol number 0-indexed end column.
---@return boolean
local function has_todo_bg_extmark(bufnr, line, scol, ecol)
  if not todo_comments_ns then todo_comments_ns = vim.api.nvim_get_namespaces()["todo-comments"] end
  if not todo_comments_ns then return false end

  local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, todo_comments_ns, { line, 0 }, { line, -1 }, { details = true })
  for _, extmark in ipairs(extmarks) do
    local _, _, mark_col, details = unpack(extmark)
    ---@cast details vim.api.keyset.extmark_details
    if not details.end_col then
      vim.notify("[todotag.nvim] Missing end_col in extmark details", vim.log.levels.ERROR, { title = "todotag.nvim" })
    else
      -- Check if extmark overlaps with the region
      if not (ecol <= mark_col or scol >= details.end_col) then
        if details.hl_group and details.hl_group:match("^TodoBg") then return true end
      end
    end
  end

  return false
end


---Add a highlight to a buffer. (0-indexed)
---@param bufnr number Buffer number.
---@param ns number Namespace ID.
---@param hl string Highlight group.
---@param line number 0-indexed line number.
---@param scol number 0-indexed start column.
---@param ecol number 0-indexed end column.
local function add_highlight(bufnr, ns, hl, line, scol, ecol)
  -- Don't add highlight if region already has `TodoBg*` extmarks
  if has_todo_bg_extmark(bufnr, line, scol, ecol) then return end

  vim.api.nvim_buf_set_extmark(bufnr, ns, line, scol, {
    end_col = ecol,
    hl_group = hl,
    priority = Config.config.priority,
  })
end


---Highlight todo-tags in a buffer between start and end rows.
---@param bufnr number Buffer number.
---@param srow number Start row (1-indexed).
---@param erow number End row (1-indexed).
function M.highlight(bufnr, srow, erow)
  -- Skip if start row > end row (invalid range)
  if srow > erow then return end

  local lines = vim.api.nvim_buf_get_lines(bufnr, srow - 1, erow, true)
  local pats = get_patterns()

  for i, line in ipairs(lines) do
    local linenr = srow + i - 1
    -- Clear existing extmarks for this line
    vim.api.nvim_buf_clear_namespace(bufnr, M.ns, linenr - 1, linenr)
    -- Use lowercase line for case-insensitive matching
    for _, pat in ipairs(pats) do
      local line_to_search = pat.case_sensitive and line or line:lower()
      local col = 1
      -- Search for pattern in the line.
      while true do
        local s, e = line_to_search:find(pat.pattern, col)
        if s == nil or e == nil then break end
        local hl_s, hl_e = s, e
        -- Compute highlight range (partial or full match)
        if pat.hl_offset and pat.hl_len then
          hl_s = s + pat.hl_offset - 1
          hl_e = hl_s + pat.hl_len - 1
        end
        if is_comment(bufnr, linenr - 1, hl_s - 1) then
          add_highlight(bufnr, M.ns, pat.hl_group, linenr - 1, hl_s - 1, hl_e)
        end
        col = e + 1
      end
    end
  end
end


-- ==================== Update ====================
local timer = vim.uv.new_timer()  -- Throttle timer

---@private
function M._update()
  for buf, state in pairs(M.state) do
    if not vim.api.nvim_buf_is_valid(buf) then M.state[buf] = nil
    else
      local todo = {}  ---@type table<number, boolean>
      if Config.config.only_visible then
        -- Only update visible regions
        local wins = vim.fn.win_findbuf(buf)
        for _, win in ipairs(wins) do
          local srow = vim.fn.line("w0", win)
          local erow = vim.fn.line("w$", win)
          for i = srow, erow do if not state.valid[i] then todo[i] = true end end
        end
      else
        -- Update entire buffer
        local lines = vim.api.nvim_buf_line_count(buf)
        for i = 1, lines do if not state.valid[i] then todo[i] = true end end
      end

      local dirty = vim.tbl_keys(todo)
      table.sort(dirty)
      if #dirty > 0 then
        local i = 1
        while i <= #dirty do
          local top, bottom = dirty[i], dirty[i]
          while i + 1 <= #dirty and dirty[i + 1] == dirty[i] + 1 do i = i + 1 bottom = dirty[i] end
          M.highlight(buf, top, bottom)
          for j = top, bottom do state.valid[j] = true end
          i = i + 1
        end
      end
    end
  end
end


function M.update()
  -- Throttle updates to improve performance
  assert(timer, "Timer not initialized!")
  if not timer:is_active() then
    timer:start(Config.config.throttle, 0, vim.schedule_wrap(M._update))
  end
end


-- ==================== Attach/Detach ====================
local function is_float(win)
  local opts = vim.api.nvim_win_get_config(win)
  return opts and opts.relative and opts.relative ~= ""
end


local function is_valid_buf(buf)
  local buftype = vim.bo[buf].buftype
  if buftype ~= "" then return false end
  if vim.tbl_contains(Config.config.exclude_bt, buftype) then return false end

  local filetype = vim.bo[buf].filetype
  if vim.tbl_contains(Config.config.exclude_ft, filetype) then return false end

  return true
end


function M.attach(win)
  win = win or vim.api.nvim_get_current_win()

  if not vim.api.nvim_win_is_valid(win) then return end
  if vim.fn.getcmdwintype() ~= "" then return end
  if is_float(win) then return end

  local buf = vim.api.nvim_win_get_buf(win)
  if not M.bufs[buf] then
    vim.api.nvim_buf_attach(buf, false, {
      on_reload = function()
        if not M.enabled or not is_valid_buf(buf) then return end
        M.invalidate(buf, 0, -1)
      end,
      on_lines = function(_event, _buf, _tick, first, _last, last_new)
        if not M.enabled then return true end
        if not is_valid_buf(buf) then return true end

        M.invalidate(buf, first, last_new)
      end,
      on_detach = function() M.state[buf] = nil M.bufs[buf] = nil end,
    })

    M.get_state(buf)  -- For init M.state[buf]; same as M.state[buf] = { valid = {} }
    M.bufs[buf] = true
  end

  if not M.wins[win] then M.wins[win] = true; M.update() end
end


-- ==================== Start/Stop ====================
---Stop the plugin: disable highlighting and detach all buffers
function M.stop()
  M.enabled = false

  M.wins = {}
  M.bufs = {}

  for buf, _ in pairs(M.bufs) do if vim.api.nvim_buf_is_valid(buf) then pcall(vim.api.nvim_buf_clear_namespace, buf, M.ns, 0, -1) end end

  -- Clear the plugin's autocmd group
  vim.api.nvim_clear_autocmds({ group = M.autocmd_group })
end


function M.start()
  if M.enabled then M.stop() end

  M.enabled = true
  M.autocmd_group = vim.api.nvim_create_augroup("todotag.nvim", { clear = true })

  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = M.autocmd_group,
    callback = function(args) M.attach() end,
    desc = "todotag.nvim buffer attach",
  })

  -- Create update autocommands in the plugin's group
  vim.api.nvim_create_autocmd("WinScrolled", {
    group = M.autocmd_group,
    callback = function(args) M.update() end,
    desc = "todotag.nvim highlight update",
  })

  -- Attach to all bufs in visible windows
  for _, win in pairs(vim.api.nvim_list_wins()) do M.attach(win) end
end


return M
