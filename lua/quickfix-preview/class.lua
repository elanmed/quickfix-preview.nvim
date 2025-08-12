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
  if vim.treesitter.highlighter.active[bufnr] then return end

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

  --- @type QuickfixItem[]
  local qf_list = vim.fn.getqflist()
  if vim.tbl_isempty(qf_list) then return end

  local curr_line_nr = vim.fn.line "."
  local curr_qf_item = qf_list[curr_line_nr]
  local path = vim.fn.bufname(curr_qf_item.bufnr)

  local pedit_cmd = string.format("%s pedit +%s %s %s", pedit_prefix, curr_qf_item.lnum, path, pedit_postfix)
  vim.cmd(pedit_cmd)

  local preview_win_id = self:get_preview_win_id()
  for win_opt_key, win_opt_val in pairs(preview_win_opts) do
    vim.wo[preview_win_id][win_opt_key] = win_opt_val
  end

  self:highlight(curr_qf_item.bufnr)
end

function QuickfixPreview:close()
  vim.cmd "pclose"
end

return QuickfixPreview
