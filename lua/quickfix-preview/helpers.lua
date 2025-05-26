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

M.get_curr_qf_index = function()
  local info = vim.fn.getqflist { ["idx"] = 0, }
  if info.idx == nil then return nil end
  return info.idx
end

--- @param circular boolean
M.get_next_qf_index = function(circular)
  local curr_qf_index = M.get_curr_qf_index()
  if curr_qf_index == nil then return nil end
  local qf_list = vim.fn.getqflist()
  if curr_qf_index == #qf_list then
    if circular then return 1 else return curr_qf_index end
  end
  return curr_qf_index + 1
end

--- @param circular boolean
M.get_prev_qf_index = function(circular)
  local curr_qf_index = M.get_curr_qf_index()
  if curr_qf_index == nil then return nil end
  local qf_list = vim.fn.getqflist()
  if curr_qf_index == 1 then
    if circular then
      return #qf_list
    else
      return curr_qf_index
    end
  end
  return curr_qf_index - 1
end

return M
