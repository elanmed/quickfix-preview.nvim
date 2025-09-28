local M = {}

--- @class QuickfixPreviewOpts
--- @field pedit_prefix? string A prefix passed to :pedit, can be used to position the preview window. Defaults to `aboveleft`
--- @field pedit_postfix? string A postfix passed to :pedit. Defaults to an empty string
--- @field preview_win_opts? vim.wo Options to apply to the preview window. Defaults to an empty table

--- @param opts QuickfixPreviewOpts | nil
M.setup = function(opts)
  local helpers = require "quickfix-preview.helpers"
  local QuickfixPreview = require "quickfix-preview.class"
  local notify_assert = require "quickfix-preview.validator".notify_assert

  --- @type Schema
  local opts_schema = {
    type = "table",
    entries = {
      preview_win_opts = {
        type = "table",
        entries = "any",
        optional = true,
      },
      pedit_prefix = {
        type = "string",
        optional = true,
      },
      pedit_postfix = {
        type = "string",
        optional = true,
      },
    },
    optional = true,
    exact = true,
  }

  if not notify_assert { schema = opts_schema, val = opts, name = "[quickfix-preview.nvim] setup.opts", } then
    return
  end

  opts = helpers.default(opts, {})
  local qf_preview = QuickfixPreview:new()

  vim.api.nvim_create_autocmd({ "CursorMoved", }, {
    callback = function()
      if vim.bo.buftype ~= "quickfix" then return end
      qf_preview:open {
        preview_win_opts = opts.preview_win_opts,
        pedit_prefix = opts.pedit_prefix,
        pedit_postfix = opts.pedit_postfix,
      }
    end,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    callback = function()
      if vim.bo.buftype ~= "quickfix" then return end
      qf_preview:close()
    end,
  })

  local toggle = function()
    if qf_preview:is_open() then
      qf_preview:set_preview_disabled(true)
      qf_preview:close()
    else
      qf_preview:set_preview_disabled(false)
      qf_preview:open {
        preview_win_opts = opts.preview_win_opts,
        pedit_prefix = opts.pedit_prefix,
        pedit_postfix = opts.pedit_postfix,
      }
    end
  end

  local select_close_preview = function()
    local curr_line = vim.fn.line "."
    qf_preview:close()
    vim.cmd("cc " .. curr_line)
    vim.schedule(function()
      vim.cmd "edit"
    end)
  end

  local select_close_quickfix = function()
    local curr_line = vim.fn.line "."
    qf_preview:close()
    vim.cmd "cclose"
    vim.cmd("cc " .. curr_line)
    vim.schedule(function()
      vim.cmd "edit"
    end)
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
    helpers.try_catch("cnext", "cfirst")
  end

  local cprev = function()
    qf_preview:close()
    helpers.try_catch("cprev", "clast")
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
end

return M
