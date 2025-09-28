--- @class QuickfixItem
--- @field bufnr number
--- @field lnum number

local QuickfixPreview = {}
QuickfixPreview.__index = QuickfixPreview

function QuickfixPreview:new()
  local this = {
    preview_disabled = false,
    preview_opened_buffers = {},
  }
  return setmetatable(this, QuickfixPreview)
end

--- @param disabled boolean
function QuickfixPreview:set_preview_disabled(disabled)
  self.preview_disabled = disabled
end

--- @param bufnr number
function QuickfixPreview:highlight(bufnr)
  local filetype = vim.filetype.match { buf = bufnr, }
  if filetype == nil then return end

  local lang_ok, lang = pcall(vim.treesitter.language.get_lang, filetype)
  if not lang_ok then return end

  pcall(vim.treesitter.start, bufnr, lang)
end

function QuickfixPreview:get_preview_win_id()
  for _, win_id in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_get_option_value("previewwindow", { win = win_id, }) then
      return win_id
    end
  end
  return nil
end

function QuickfixPreview:is_open()
  return self:get_preview_win_id() ~= nil
end

--- @class QuickfixPreviewOpenOpts
--- @field pedit_prefix? string
--- @field pedit_postfix? string
--- @field preview_win_opts? vim.wo

--- @param opts QuickfixPreviewOpenOpts
function QuickfixPreview:open(opts)
  if self.preview_disabled then return end

  local h = require "quickfix-preview.helpers"
  opts = h.default(opts, {})
  local pedit_prefix = h.default(opts.pedit_prefix, "aboveleft")
  local pedit_postfix = h.default(opts.pedit_postfix, "")
  local preview_win_opts = h.default(opts.preview_win_opts, {})

  local pedit_winnr = self:get_preview_win_id()
  local prev_pedit_bufname = (function()
    if not pedit_winnr then return nil end
    local bufnr = vim.api.nvim_win_get_buf(pedit_winnr)
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    return bufname
  end)()

  --- @type QuickfixItem[]
  local qf_list = vim.fn.getqflist()
  if vim.tbl_isempty(qf_list) then return end

  local curr_line_nr = vim.fn.line "."
  local curr_qf_item = qf_list[curr_line_nr]
  local path = vim.fn.bufname(curr_qf_item.bufnr)
  local is_loaded = vim.api.nvim_buf_is_loaded(curr_qf_item.bufnr)

  if pedit_winnr and prev_pedit_bufname == vim.api.nvim_buf_get_name(curr_qf_item.bufnr) then
    vim.api.nvim_win_set_cursor(pedit_winnr, { curr_qf_item.lnum, 0, })
  else
    local pedit_cmd = string.format("%s pedit +%s %s %s", pedit_prefix, curr_qf_item.lnum, path, pedit_postfix)
    vim.cmd(pedit_cmd)
  end

  if not is_loaded then
    self.preview_opened_buffers[curr_qf_item.bufnr] = true
  end

  if self.preview_opened_buffers[curr_qf_item.bufnr] then
    vim.api.nvim_set_option_value("buflisted", false, { buf = curr_qf_item.bufnr, })
    vim.api.nvim_set_option_value("bufhidden", "delete", { buf = curr_qf_item.bufnr, })
  end

  local preview_win_id = self:get_preview_win_id()
  for win_opt_key, win_opt_val in pairs(preview_win_opts) do
    vim.api.nvim_set_option_value(win_opt_key, win_opt_val, { win = preview_win_id, })
  end

  self:highlight(curr_qf_item.bufnr)
end

function QuickfixPreview:close()
  self.preview_opened_buffers = {}
  vim.cmd "pclose"
end

return QuickfixPreview
