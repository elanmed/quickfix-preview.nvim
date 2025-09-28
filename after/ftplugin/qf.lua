if vim.b.quickfix_preview_initialized then
  return
end
vim.b.quickfix_preview_initialized = true
local bufnr = vim.api.nvim_get_current_buf()

local QuickfixPreview = require "quickfix-preview.class"
local qf_preview = QuickfixPreview:new()

--- @param try string
--- @param catch string
local try_catch = function(try, catch)
  local success, _ = pcall(vim.cmd, try)
  if not success then
    pcall(vim.cmd, catch)
  end
end


vim.api.nvim_create_autocmd({ "CursorMoved", }, {
  buffer = bufnr,
  callback = function()
    qf_preview:open()
  end,
})

vim.api.nvim_create_autocmd("WinClosed", {
  buffer = bufnr,
  callback = function()
    qf_preview:close()
  end,
})

local toggle = function()
  if qf_preview:is_open() then
    qf_preview:set_preview_disabled(true)
    qf_preview:close()
  else
    qf_preview:set_preview_disabled(false)
    qf_preview:open()
  end
end

local select_close_preview = function()
  local curr_line = vim.fn.line "."
  qf_preview:close()
  vim.cmd("cc " .. curr_line)
end

local select_close_quickfix = function()
  local curr_line = vim.fn.line "."
  qf_preview:close()
  vim.cmd "cclose"
  vim.cmd("cc " .. curr_line)
end

local next = function()
  local next_qf_index = (function()
    local curr_qf_index = vim.fn.line "."
    if curr_qf_index == nil then return nil end
    local qf_list = vim.fn.getqflist()
    if curr_qf_index == #qf_list then
      return 1
    end
    return curr_qf_index + 1
  end)()

  if next_qf_index == nil then return end
  vim.fn.setqflist({}, "a", { ["idx"] = next_qf_index, })
end

local prev = function()
  local prev_qf_index = (function()
    local curr_qf_index = vim.fn.line "."
    if curr_qf_index == nil then return nil end
    local qf_list = vim.fn.getqflist()
    if curr_qf_index == 1 then
      return #qf_list
    end
    return curr_qf_index - 1
  end)()

  if prev_qf_index == nil then return end
  vim.fn.setqflist({}, "a", { ["idx"] = prev_qf_index, })
end

local cnext = function()
  qf_preview:close()
  try_catch("cnext", "cfirst")
end

local cprev = function()
  qf_preview:close()
  try_catch("cprev", "clast")
end

local keymap_fns = {
  Toggle = toggle,
  SelectClosePreview = select_close_preview,
  SelectCloseQuickfix = select_close_quickfix,
  Next = next,
  Prev = prev,
  CNext = cnext,
  CPrev = cprev,
}

for action, fn in pairs(keymap_fns) do
  vim.keymap.set("n", "<Plug>QuickfixPreview" .. action, fn, { desc = "QuickfixPreview: " .. action, })
end
