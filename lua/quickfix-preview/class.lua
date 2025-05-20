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
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd "filetype detect"
      pcall(vim.treesitter.start, bufnr)
    end)
    self.parsed_buffers[bufnr] = true
  end
end

function QuickfixPreview:is_open()
  for _, win_id in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_get_option_value("previewwindow", { win = win_id, }) then
      return true
    end
  end
  return false
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

  self:highlight(curr_qf_item.bufnr)
end

function QuickfixPreview:close()
  vim.cmd "pclose"
end

return QuickfixPreview
