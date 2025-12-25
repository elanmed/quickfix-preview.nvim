--- @generic T
--- @param val T | nil
--- @param fallback T
--- @return T
local if_nil = function(val, fallback)
  if val == nil then
    return fallback
  end
  return val
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

--- @class SetPreviewLinesOpts
--- @field end_linenr number
--- @field curr_qf_item QuickfixItem
--- @param opts SetPreviewLinesOpts
function QuickfixPreview:set_preview_lines(opts)
  local abs_path = (function()
    local get_abs_filename = function()
      if opts.curr_qf_item.filename == nil then return nil end
      vim.fs.normalize(vim.fs.abspath(opts.curr_qf_item.filename))
    end

    if opts.curr_qf_item.bufnr == nil then return get_abs_filename() end
    if not vim.api.nvim_buf_is_valid(opts.curr_qf_item.bufnr) then return get_abs_filename() end
    return vim.api.nvim_buf_get_name(opts.curr_qf_item.bufnr)
  end)()

  if abs_path == nil or vim.uv.fs_stat(abs_path) == nil then
    vim.api.nvim_buf_set_lines(self.preview_bufnr, 0, -1, false,
      { "[quickfix-preview.nvim]: File cannot be previewed", }
    )
    return false
  end

  local preview_lines = {}
  local idx = 1

  for line in io.lines(abs_path) do
    table.insert(preview_lines, line)
    if idx == opts.end_linenr then break end
    idx = idx + 1
  end

  vim.api.nvim_buf_set_lines(self.preview_bufnr, 0, -1, false, preview_lines)
  return true
end

function QuickfixPreview:open()
  if self.preview_disabled then return end

  --- @class QuickfixPreviewOpenOpts
  --- @field preview_win_opts? vim.wo
  --- @field open_preview_win_opts? vim.api.keyset.win_config

  --- @type QuickfixPreviewOpenOpts
  local opts = if_nil(vim.g.quickfix_preview, {})
  local preview_win_opts = if_nil(opts.preview_win_opts, {
    cursorline = true,
    number = true,
  })
  local open_preview_win_opts = if_nil(opts.open_preview_win_opts, {
    style = "minimal",
    split = "right",
    width = math.floor(vim.o.columns / 2),
  })

  --- @type QuickfixItem[]
  local qf_list = vim.fn.getqflist()
  if #qf_list == 0 then return end

  local curr_qf_item = qf_list[vim.fn.line "."]

  if not vim.api.nvim_win_is_valid(self.preview_winnr) then
    self.preview_bufnr = vim.api.nvim_create_buf(false, true)
    self.preview_winnr = vim.api.nvim_open_win(self.preview_bufnr, false, open_preview_win_opts)
    vim.api.nvim_set_option_value("filetype", "quickfix-preview", { buf = self.preview_bufnr, })
  end

  for win_opt_key, win_opt_val in pairs(preview_win_opts) do
    vim.api.nvim_set_option_value(win_opt_key, win_opt_val, { win = self.preview_winnr, })
  end

  local lnum = curr_qf_item.lnum or 1
  local success = self:set_preview_lines {
    curr_qf_item = curr_qf_item,
    end_linenr = self:get_end_linenr(lnum),
  }
  if success then
    vim.api.nvim_win_set_cursor(self.preview_winnr, { lnum, 0, })
  end
  vim.api.nvim_win_call(self.preview_winnr, function()
    vim.cmd "normal! zz"
  end)

  local filetype = vim.filetype.match { buf = curr_qf_item.bufnr, }
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

--- @param lnum number
function QuickfixPreview:get_end_linenr(lnum)
  local preview_height = vim.api.nvim_win_get_height(self.preview_winnr)
  local scroll = vim.wo[self.preview_winnr].scroll
  local max_visible_screen = lnum + preview_height - 1
  return max_visible_screen + scroll
end

function QuickfixPreview:scroll_down()
  --- @type QuickfixItem[]
  local qf_list = vim.fn.getqflist()
  if #qf_list == 0 then return end

  local curr_qf_item = qf_list[vim.fn.line "."]

  vim.api.nvim_win_call(self.preview_winnr, function()
    vim.cmd 'execute "normal! \\<C-d>"'
    vim.cmd "normal! zz"
  end)

  local lnum = unpack(vim.api.nvim_win_get_cursor(self.preview_winnr))

  self:set_preview_lines {
    curr_qf_item = curr_qf_item,
    end_linenr = self:get_end_linenr(lnum),
  }
end

function QuickfixPreview:scroll_up()
  vim.api.nvim_win_call(self.preview_winnr, function()
    vim.cmd 'execute "normal! \\<C-u>"'
    vim.cmd "normal! zz"
  end)
end

return QuickfixPreview
