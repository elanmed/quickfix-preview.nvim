if vim.b.quickfix_preview_initialized then
  return
end
vim.b.quickfix_preview_initialized = true
local bufnr = vim.api.nvim_get_current_buf()

local QuickfixPreview = require "quickfix-preview.class"
local qf_preview = QuickfixPreview:new()


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

local keymap_fns = {
  Toggle = toggle,
  Next = next,
  Prev = prev,
}

for action, fn in pairs(keymap_fns) do
  vim.keymap.set("n", "<Plug>QuickfixPreview" .. action, fn, { desc = "QuickfixPreview: " .. action, })
end

vim.api.nvim_create_user_command("QuickfixPreviewClosePreview", function()
  qf_preview:close()
end, { nargs = 0, })
