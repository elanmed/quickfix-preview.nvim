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

local keymap_fns = {
  Toggle = toggle,
}

for action, fn in pairs(keymap_fns) do
  vim.keymap.set("n", "<Plug>QuickfixPreview" .. action, fn, { desc = "QuickfixPreview: " .. action, })
end

vim.api.nvim_create_user_command("QuickfixPreviewClosePreview", function()
  qf_preview:close()
end, { nargs = 0, })
