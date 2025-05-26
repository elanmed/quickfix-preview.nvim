local helpers = require "quickfix-preview.helpers"

--- @class QuickfixItem
--- @field bufnr number
--- @field lnum number

local QuickfixPreview = {}
QuickfixPreview.__index = QuickfixPreview

function QuickfixPreview:new()
  local this = {
    preview_disabled = false,
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
  local lang = vim.treesitter.language.get_lang(filetype)
  vim.treesitter.start(bufnr, lang)
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

--- @param pedit_prefix? string
--- @param pedit_postfix? string
function QuickfixPreview:open(pedit_prefix, pedit_postfix)
  if self.preview_disabled then return end
  local defaulted_pedit_prefix = helpers.default(pedit_prefix, "aboveleft")
  local defaulted_pedit_postfix = helpers.default(pedit_postfix, "")

  --- @type QuickfixItem[]
  local qf_list = vim.fn.getqflist()
  if vim.tbl_isempty(qf_list) then return end

  local curr_line_nr = vim.fn.line "."
  local curr_qf_item = qf_list[curr_line_nr]
  local path         = vim.fn.bufname(curr_qf_item.bufnr)

  local pedit_cmd    = string.format("%s pedit +%s %s %s", defaulted_pedit_prefix, curr_qf_item.lnum, path,
    defaulted_pedit_postfix)
  vim.cmd(pedit_cmd)

  local preview_win_id                  = self:get_preview_win_id()
  vim.wo[preview_win_id].relativenumber = false
  vim.wo[preview_win_id].number         = true
  vim.wo[preview_win_id].signcolumn     = "no"
  vim.wo[preview_win_id].cursorline     = true

  self:highlight(curr_qf_item.bufnr)
end

function QuickfixPreview:close()
  vim.cmd "pclose"
end

return QuickfixPreview
