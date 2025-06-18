local M = {}

--- @class QuickfixPreviewOpts
--- @field pedit_prefix? string A prefix passed to :pedit, can be used to position the preview window. Defaults to `aboveleft`
--- @field pedit_postfix? string A postfix passed to :pedit. Defaults to an empty string
--- @field preview_win_opts? vim.wo Options to apply to the preview window. Defaults to an empty table
--- @field keymaps? QuickfixPreviewKeymaps Keymaps, defaults to none

--- @class QuickfixPreviewKeymaps
--- @field toggle? string Toggle the quickfix preview
--- @field select_close_preview? string Open the file undor the cursor, keeping the quickfix list open
--- @field select_close_quickfix? string Open the file under the cursor, closing the quickfix list
--- @field next? QuickFixPreviewKeymapCircularOpts | string :cnext, preserving focus on the quickfix list
--- @field prev? QuickFixPreviewKeymapCircularOpts | string :cprev, preserving focus on the quickfix list
--- @field cnext? QuickFixPreviewKeymapCircularOpts | string :cnext, closing the preview first
--- @field cprev? QuickFixPreviewKeymapCircularOpts | string :cprev, closing the preview first

--- @class QuickFixPreviewKeymapCircularOpts
--- @field key string The key to set as the remap
--- @field circular? boolean Whether the next/prev command should circle back to the beginning/end. Defaults to `true`

--- @param opts QuickfixPreviewOpts | nil
M.setup = function(opts)
  local helpers = require "quickfix-preview.helpers"
  local QuickfixPreview = require "quickfix-preview.class"
  local validate = require "quickfix-preview.validator".validate
  local union = require "quickfix-preview.validator".union

  --- @type Schema
  local circular_keymap_schema = {
    type = union {
      { type = "string", },
      {
        type = "table",
        entries = {
          key = { type = "string", },
          circular = { type = "boolean", optional = true, },
        },
        exact = true,
      },
    },
    optional = true,
  }

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
      keymaps = {
        type = "table",
        optional = true,
        entries = {
          toggle = { type = "string", optional = true, },
          select_close_preview = { type = "string", optional = true, },
          select_close_quickfix = { type = "string", optional = true, },
          next = circular_keymap_schema,
          prev = circular_keymap_schema,
          cnext = circular_keymap_schema,
          cprev = circular_keymap_schema,
        },
        exact = true,
      },
    },
    optional = true,
    exact = true,
  }

  if not validate(opts_schema, opts) then
    vim.notify(
      string.format(
        "Malformed opts passed to quickfix-preview.setup! Expected %s, received %s",
        vim.inspect(opts_schema),
        vim.inspect(opts)
      ),
      vim.log.levels.ERROR
    )
    return
  end

  opts = helpers.default(opts, {})
  local keymaps = helpers.default(opts.keymaps, {})
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
            qf_preview:open {
              preview_win_opts = opts.preview_win_opts,
              pedit_prefix = opts.pedit_prefix,
              pedit_postfix = opts.pedit_postfix,
            }
          end
        end, { buffer = true, desc = "Toggle the quickfix preview", })
      end

      if keymaps.select_close_preview then
        vim.keymap.set("n", keymaps.select_close_preview, function()
          local curr_line_nr = vim.fn.line "."

          qf_preview:close()
          vim.cmd("cc " .. curr_line_nr)
          vim.schedule(function()
            vim.cmd "edit"
          end)
        end, { buffer = true, desc = "Open the file undor the cursor, keeping the quickfix list open", })
      end

      if keymaps.select_close_quickfix then
        vim.keymap.set("n", keymaps.select_close_quickfix, function()
          local curr_line_nr = vim.fn.line "."

          qf_preview:close()
          vim.cmd "cclose"
          vim.cmd("cc " .. curr_line_nr)
          vim.schedule(function()
            vim.cmd "edit"
          end)
        end, { buffer = true, desc = "Open the file under the cursor, closing the quickfix list", })
      end

      if keymaps.next then
        local circular = helpers.default(keymaps.next.circular, true)

        vim.keymap.set("n", keymaps.next.key, function()
          local next_qf_index = helpers.get_next_qf_index(circular)
          if next_qf_index == nil then return end
          vim.fn.setqflist({}, "a", { ["idx"] = next_qf_index, })
        end, { buffer = true, desc = ":cnext, preserving focus on the quickfix list", })
      end

      if keymaps.prev then
        local circular = helpers.default(keymaps.prev.circular, true)

        vim.keymap.set("n", keymaps.prev.key, function()
          local prev_qf_index = helpers.get_prev_qf_index(circular)
          if prev_qf_index == nil then return end
          vim.fn.setqflist({}, "a", { ["idx"] = prev_qf_index, })
        end, { buffer = true, desc = ":cprev, preserving focus on the quickfix list", })
      end
    end,
  })

  if keymaps.cnext then
    local circular = helpers.default(keymaps.cnext.circular, true)

    vim.keymap.set("n", keymaps.cnext.key, function()
      qf_preview:close()
      if circular then helpers.try_catch("cnext", "cfirst") else vim.cmd "cnext" end
    end, { desc = ":cnext, closing the preview first", })
  end

  if keymaps.cprev then
    local circular = helpers.default(keymaps.cprev.circular, true)

    vim.keymap.set("n", keymaps.cprev.key, function()
      qf_preview:close()
      if circular then helpers.try_catch("cprev", "clast") else vim.cmd "cprev" end
    end, { desc = ":cprev, closing the preview first", })
  end
end

return M
