local QuickfixPreview = require "quickfix-preview.class"
local qf_preview = QuickfixPreview:new()
local M = {}

M.close = function()
  qf_preview:close()
end

M.open = function()
  qf_preview:open()
end

--- @param is_disabled boolean
M.set_preview_disabled = function(is_disabled)
  qf_preview:set_preview_disabled(is_disabled)
end

--- @param try string
--- @param catch string
local function try_catch(try, catch)
  local success, _ = pcall(vim.cmd, try)
  if not success then
    pcall(vim.cmd, catch)
  end
end

--- @generic T
--- @param val T | nil
--- @param default_val T
--- @return T
local function default(val, default_val)
  if val == nil then
    return default_val
  end
  return val
end

--- @class QuickfixPreviewOpts
--- @field keymaps QuickfixPreviewKeymaps Keymaps, defaults to none

--- @class QuickfixPreviewKeymaps
--- @field toggle string Toggle the preview
--- @field open string Open the file under the cursor, keep the quickfix list open
--- @field openc string Open the file under the cursor, close the quickfix list
--- @field next QuickFixPreviewKeymapCircularOpts | string :cnext, keep the quickfix list open
--- @field prev QuickFixPreviewKeymapCircularOpts | string :cprev, keep the quickfix list open
--- @field cnext QuickFixPreviewKeymapCircularOpts | string :cnext, closing the preview first
--- @field cprev QuickFixPreviewKeymapCircularOpts | string :cprev, closing the preview first

--- @class QuickFixPreviewKeymapCircularOpts
--- @field key string The key to set as the remap
--- @field circular boolean Whether the next/prev command should circle back to the beginning/end. Defaults to `true`

--- @param opts QuickfixPreviewOpts | nil
M.setup = function(opts)
  opts = default(opts, {})
  local keymaps = default(opts.keymaps, {})

  vim.api.nvim_create_autocmd({ "CursorMoved", }, {
    callback = function()
      if vim.bo.buftype ~= "quickfix" then return end
      qf_preview:open()
    end,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    callback = function()
      if vim.bo.buftype ~= "quickfix" then return end
      qf_preview:close()
    end,
  })

  vim.api.nvim_create_autocmd({ "FileType", }, {
    callback = function()
      if vim.bo.buftype ~= "quickfix" then return end

      if keymaps.toggle then
        vim.keymap.set("n", keymaps.toggle, function()
          if qf_preview:is_open() then
            qf_preview:set_preview_disabled(true)
            qf_preview:close()
          else
            qf_preview:set_preview_disabled(false)
            qf_preview:open()
          end
        end, { buffer = true, desc = "Toggle the quickfix preview.", })
      end

      if keymaps.open then
        vim.keymap.set("n", keymaps.open, function()
          local curr_line_nr = vim.fn.line "."
          qf_preview:close()
          vim.cmd("cc " .. curr_line_nr)
        end, { buffer = true, desc = "Open the file undor the cursor, keeping the quickfix list open", })
      end

      if keymaps.openc then
        vim.keymap.set("n", keymaps.openc, function()
          local curr_line = vim.fn.line "."
          vim.cmd "cclose"
          qf_preview:close()
          vim.cmd("cc " .. curr_line)
        end, { buffer = true, desc = "Open the file under the cursor, closing the quickfix list", })
      end

      if keymaps.next then
        vim.keymap.set("n", keymaps.next.key, function()
          qf_preview:close()
          try_catch("cnext", "cfirst")
          vim.cmd "copen"
        end, { buffer = true, desc = "Go to the next file, preserving focus on the quickfix list", })
      end

      if keymaps.prev then
        vim.keymap.set("n", keymaps.prev.key, function()
          qf_preview:close()
          try_catch("cprev", "clast")
          vim.cmd "copen"
        end, { buffer = true, desc = "Go to the prev file, preserving focus on the quickfix list", })
      end
    end,
  })

  if keymaps.cnext then
    vim.keymap.set("n", keymaps.next, function()
      qf_preview:close()
      try_catch("cnext", "cfirst")
    end, { desc = "Go to the next file, losing focus on the quickfix list", })
  end

  if keymaps.cprev then
    vim.keymap.set("n", keymaps.prev, function()
      qf_preview:close()
      try_catch("cprev", "clast")
    end, { desc = "Go to the prev file, losing focus on the quickfix list", })
  end
end

return M
