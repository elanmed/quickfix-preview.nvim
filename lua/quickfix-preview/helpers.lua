local M = {}

--- @param try string
--- @param catch string
M.try_catch = function(try, catch)
  local success, _ = pcall(vim.cmd, try)
  if not success then
    pcall(vim.cmd, catch)
  end
end

--- @generic T
--- @param val T | nil
--- @param default_val T
--- @return T
M.default = function(val, default_val)
  if val == nil then
    return default_val
  end
  return val
end

return M
