--- @class QuickfixItem
--- @field bufnr number
--- @field lnum number

local QuickfixPreview = {}
QuickfixPreview.__index = QuickfixPreview

function QuickfixPreview:new()
  local this = {
    preview_disabled = false,
    parsed_buffers = {},
  }
  return setmetatable(this, QuickfixPreview)
end

--- @param disabled boolean
function QuickfixPreview:set_preview_disabled(disabled)
  self.preview_disabled = disabled
end

--- @param bufnr number
function QuickfixPreview:highlight(bufnr)
  if not self.parsed_buffers[bufnr] then
    local filetype = vim.filetype.match { buf = bufnr, }
    if filetype == nil then return end
    local lang = vim.treesitter.language.get_lang(filetype)
    vim.treesitter.start(bufnr, lang)

    self.parsed_buffers[bufnr] = true
  end
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

function QuickfixPreview:open()
  if self.preview_disabled then return end

  --- @type QuickfixItem[]
  local qf_list = vim.fn.getqflist()
  if vim.tbl_isempty(qf_list) then return end

  local curr_line_nr = vim.fn.line "."
  local curr_qf_item = qf_list[curr_line_nr]
  local path         = vim.fn.bufname(curr_qf_item.bufnr)


  vim.cmd("aboveleft pedit +" .. curr_qf_item.lnum .. " " .. path)

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
