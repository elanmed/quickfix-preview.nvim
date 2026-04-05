if vim.b.quickfix_preview_initialized then
  return
end
vim.b.quickfix_preview_initialized = true
local bufnr = vim.api.nvim_get_current_buf()

local QuickfixPreview = require "quickfix-preview.class"
local qf_preview = QuickfixPreview:new()


vim.api.nvim_create_autocmd("CursorMoved", {
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

local scroll_down = function() qf_preview:scroll_down() end
local scroll_up = function() qf_preview:scroll_up() end

--- Plug remaps ~
---
--- `<Plug>QuickfixPreviewToggle` ~
--- Toggle the quickfix preview.
---
--- `<Plug>QuickfixPreviewScrollDown` ~
--- Scroll the quickfix preview down by |scroll| lines.
---
--- `<Plug>QuickfixPreviewScrollUp` ~
--- Scroll the quickfix preview up by |scroll| lines.
--- @tag quickfix-preview-plug-remaps

local keymap_fns = {
  Toggle = toggle,
  ScrollDown = scroll_down,
  ScrollUp = scroll_up,
}

for action, fn in pairs(keymap_fns) do
  vim.keymap.set("n", "<Plug>QuickfixPreview" .. action, fn, { desc = "QuickfixPreview: " .. action, })
end

--- User commands ~
---
--- `QuickfixPreviewClosePreview` ~
--- Manually close the preview.
--- @tag quickfix-preview-commands

vim.api.nvim_create_user_command("QuickfixPreviewClosePreview", function()
  qf_preview:close()
end, { nargs = 0, })
