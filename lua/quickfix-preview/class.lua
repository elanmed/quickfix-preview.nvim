--- @generic T
--- @param val T | nil
--- @param default_val T
--- @return T
local default = function(val, default_val)
  if val == nil then
    return default_val
  end
  return val
end

--- @class GetLinesOpts
--- @field abs_path string
--- @field end_line number
--- @param opts GetLinesOpts
local function get_lines(opts)
  --- @type string[]
  local lines = {}
  local idx = 1
  for line in io.lines(opts.abs_path) do
    table.insert(lines, line)
    if idx == opts.end_line then break end
    idx = idx + 1
  end
  return lines
end

--- @class QuickfixItem
--- @field bufnr number
--- @field filename string
--- @field lnum number

local QuickfixPreview = {}
QuickfixPreview.__index = QuickfixPreview

function QuickfixPreview:new()
  local this = {
    preview_disabled = false,
    preview_winnr = -1,
    preview_bufnr = -1,
  }
  return setmetatable(this, QuickfixPreview)
end

--- @param disabled boolean
function QuickfixPreview:set_preview_disabled(disabled)
  self.preview_disabled = disabled
end

function QuickfixPreview:is_open()
  return vim.api.nvim_win_is_valid(self.preview_winnr)
end

function QuickfixPreview:open()
  if self.preview_disabled then return end

  --- @class QuickfixPreviewOpenOpts
  --- @field preview_win_opts? vim.wo
  --- @field open_preview_win_opts? vim.api.keyset.win_config

  --- @type QuickfixPreviewOpenOpts
  local opts = default(vim.g.quickfix_preview, {})
  local preview_win_opts = default(opts.preview_win_opts, {
    cursorline = true,
    number = true,
  })
  local open_preview_win_opts = default(opts.open_preview_win_opts, {
    style = "minimal",
    split = "right",
    width = math.floor(vim.o.columns / 2),
  })

  --- @type QuickfixItem[]
  local qf_list = vim.fn.getqflist()
  if #qf_list == 0 then return end

  local curr_line_nr = vim.fn.line "."
  local curr_qf_item = qf_list[curr_line_nr]

  if not vim.api.nvim_win_is_valid(self.preview_winnr) then
    self.preview_bufnr = vim.api.nvim_create_buf(false, true)
    self.preview_winnr = vim.api.nvim_open_win(self.preview_bufnr, false, open_preview_win_opts)
    vim.api.nvim_set_option_value("filetype", "quickfix-preview", { buf = self.preview_bufnr, })
  end

  local abs_path = (function()
    if not curr_qf_item.bufnr or not vim.api.nvim_buf_is_valid(curr_qf_item.bufnr) then
      return vim.fs.abspath(curr_qf_item.filename)
    end
    return vim.api.nvim_buf_get_name(curr_qf_item.bufnr)
  end)()

  if vim.uv.fs_stat(abs_path) == nil then
    vim.api.nvim_buf_set_lines(self.preview_bufnr, 0, -1, false, { "[quickfix-preview.nvim]: Unable to preview file", })
    return
  end

  local preview_height = vim.api.nvim_win_get_height(0)
  local lines = get_lines {
    abs_path = abs_path,
    end_line = curr_qf_item.lnum + preview_height,
  }
  vim.api.nvim_buf_set_lines(self.preview_bufnr, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(self.preview_winnr, { curr_qf_item.lnum, 0, })

  for win_opt_key, win_opt_val in pairs(preview_win_opts) do
    vim.api.nvim_set_option_value(win_opt_key, win_opt_val, { win = self.preview_winnr, })
  end

  local filetype = vim.filetype.match { filename = abs_path, }
  if filetype == nil then return end

  local lang_ok, lang = pcall(vim.treesitter.language.get_lang, filetype)
  if not lang_ok then return end

  pcall(vim.treesitter.start, self.preview_bufnr, lang)
end

function QuickfixPreview:close()
  if vim.api.nvim_win_is_valid(self.preview_winnr) then
    vim.api.nvim_win_close(self.preview_winnr, true)
  end
end

return QuickfixPreview
