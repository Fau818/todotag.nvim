---@class Todotag.Config
---@field keywords table<string, Todotag.Config.KeywordOptions> Keywords recognized as todo tags.
---@field priority number? Priority of the highlights.
---@field throttle number? Throttle time in milliseconds.
---@field only_visible boolean? Whether to only show todo tags in the visible area.
---@field exclude_ft string[]? Filetypes to exclude.
---@field exclude_bt string[]? Buffer types to exclude.


---@class Todotag.Config.KeywordOptions
---@field hl_group string Highlight group to use for this keyword.
---@field case_sensitive boolean? Whether the keyword matching is case-sensitive.



---@class Todotag.Patterns
---@field pattern string The Lua pattern to match.
---@field hl_group string The highlight group to use.
---@field case_sensitive boolean Whether the pattern is case-sensitive.
