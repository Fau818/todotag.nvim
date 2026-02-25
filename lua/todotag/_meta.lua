---@class Todotag.Config
---@field keywords Todotag.Config.KeywordOptions[] Keywords recognized as todo tags.
---@field priority number? Priority of the highlights.
---@field throttle number? Throttle time in milliseconds.
---@field only_visible boolean? Whether to only show todo tags in the visible area.
---@field exclude_ft string[]? Filetypes to exclude.
---@field exclude_bt string[]? Buffer types to exclude.


---@class Todotag.Config.KeywordOptions
---@field pattern string The match pattern string.
---@field hl_group string Highlight group to use for this keyword.
---@field case_sensitive boolean? Whether the keyword matching is case-sensitive.
---@field hl_part string? Substring within the match to highlight. Must be a contiguous substring of `pattern`. If omitted, the entire match is highlighted.



---@class Todotag.Patterns
---@field pattern string The Lua pattern to match.
---@field hl_group string The highlight group to use.
---@field case_sensitive boolean Whether the pattern is case-sensitive.
---@field hl_offset number? 1-indexed offset of the highlight region within the match. nil means highlight entire match.
---@field hl_len number? Length of the highlight region in characters.
