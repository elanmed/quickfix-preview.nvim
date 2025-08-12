local expect = MiniTest.expect

local child = MiniTest.new_child_neovim()
local file_name = "test_file.lua"

local function get_preview_win_id()
  for _, win_id in ipairs(child.api.nvim_list_wins()) do
    if child.api.nvim_get_option_value("previewwindow", { win = win_id, }) then
      return win_id
    end
  end
  return nil
end

local function get_quickfix_win_id()
  for _, win_id in ipairs(child.api.nvim_list_wins()) do
    local bufnr = child.api.nvim_win_get_buf(win_id)
    local buf_type = child.api.nvim_get_option_value("buftype", { buf = bufnr, })
    if buf_type == "quickfix" then
      return win_id
    end
  end
  return nil
end

local function get_file_win_id()
  for _, win_id in ipairs(child.api.nvim_list_wins()) do
    local bufnr = child.api.nvim_win_get_buf(win_id)
    local buf_name = vim.fs.basename(child.api.nvim_buf_get_name(bufnr))
    if buf_name == file_name then
      return win_id
    end
  end
  return nil
end

local expect_preview_visible = MiniTest.new_expectation(
  "quickfix preview visible",
  function(is)
    local preview_win_id = get_preview_win_id()
    return is and preview_win_id ~= nil or preview_win_id == nil
  end,
  function(is)
    if is then
      return "Expected the preview to be visible, was not."
    else
      return "Expected the preview not to be visible, was."
    end
  end
)

local expect_quickfix_visible = MiniTest.new_expectation(
  "quickfix list visible",
  function(is)
    local quickfix_win_id = get_quickfix_win_id()
    return is and quickfix_win_id ~= nil or quickfix_win_id == nil
  end,
  function(is)
    if is then
      return "Expected the quickfix list to be visible, was not."
    else
      return "Expected the quickfix list not to be visible, was."
    end
  end
)

--- @param win_id number
local function get_win_info(win_id)
  local row, col_0_indexed = table.unpack(child.api.nvim_win_get_cursor(win_id))
  local col = col_0_indexed + 1

  local bufnr = child.api.nvim_win_get_buf(win_id)
  local buf_path = vim.fs.basename(child.api.nvim_buf_get_name(bufnr))

  return {
    row = row,
    col = col,
    buf_path = buf_path,
  }
end

local T = MiniTest.new_set {
  hooks = {
    pre_case = function()
      child.restart { "-u", "scripts/minimal_init.lua", }
      child.bo.readonly = false
      child.lua [[require "nvim-treesitter.configs".setup {} ]]
      child.lua [[M = require('quickfix-preview')]]

      local lines = { "-- alpha", "-- bravo", "-- charlie", }
      child.fn.writefile(lines, file_name)
      child.cmd("edit " .. file_name)

      local bufnr = child.api.nvim_get_current_buf()

      local qf_items = {}
      for index, line in pairs(lines) do
        table.insert(qf_items, {
          bufnr = bufnr,
          lnum = index,
          col = 1,
          text = line,
        })
      end
      child.fn.setqflist(qf_items, "r")
    end,
    post_once = function()
      child.fn.delete(file_name)
      child.stop()
    end,
  },
}

T["setup"] = MiniTest.new_set()
T["setup"]["autocommands"] = MiniTest.new_set {
  hooks = {
    pre_case = function()
      child.lua "M.setup()"
    end,
  },
}
T["setup"]["autocommands"]["should open the preview on copen"] = function()
  child.cmd "copen"
  expect_preview_visible(true)
  local win_info = get_win_info(get_preview_win_id())
  expect.equality(win_info.row, 1)
  expect.equality(win_info.buf_path, file_name)
end
T["setup"]["autocommands"]["should refresh the preview on cursor move"] = function()
  child.cmd "copen"
  child.type_keys "j"
  expect_preview_visible(true)
  local win_info = get_win_info(get_preview_win_id())
  expect.equality(win_info.row, 2)
  expect.equality(win_info.buf_path, file_name)
end
T["setup"]["autocommands"]["should close the preview on cclose"] = function()
  child.cmd "copen"
  expect_preview_visible(true)
  child.cmd "cclose"
  expect_preview_visible(false)
end

T["setup"]["preview_win_opts"] = function()
  child.lua [[ M.setup { preview_win_opts = { number = true, cursorline = true }, } ]]
  child.cmd "copen"
  expect_preview_visible(true)
  local preview_win_id = get_preview_win_id()
  local number_opt = child.api.nvim_get_option_value("number", { win = preview_win_id, })
  expect.equality(number_opt, true) -- defaults to `false`
  local cursorline_opt = child.api.nvim_get_option_value("cursorline", { win = preview_win_id, })
  expect.equality(cursorline_opt, true) -- defaults to `false`
end

T["setup"]["pedit_prefix"] = function()
  child.lua [[ M.setup { pedit_prefix = "let g:pedit_prefix = 'prefix applied' |", } ]]
  child.cmd "copen"
  expect.equality(child.lua_get "vim.g.pedit_prefix", "prefix applied")
end
T["setup"]["pedit_postfix"] = function()
  child.lua [[ M.setup { pedit_postfix = "| let g:pedit_postfix = 'postfix applied'", } ]]
  child.cmd "copen"
  expect.equality(child.lua_get "vim.g.pedit_postfix", "postfix applied")
end

T["setup"]["keymaps"] = MiniTest.new_set()
T["setup"]["keymaps"]["toggle should toggle the preview"] = function()
  child.lua [[ M.setup { keymaps = { toggle = "t", }, } ]]
  child.cmd "copen"
  expect_preview_visible(true)
  child.type_keys "t"
  expect_preview_visible(false)
  child.type_keys "t"
  expect_preview_visible(true)
end
T["setup"]["keymaps"]["select_close_preview should open the current item, keep the quickfix list open"] = function()
  child.lua [[ M.setup { keymaps = { select_close_preview = "o", }, } ]]
  child.cmd "copen"
  expect_preview_visible(true)
  expect_quickfix_visible(true)
  child.type_keys "j"
  expect_preview_visible(true)
  expect_quickfix_visible(true)
  child.type_keys "o"
  expect_preview_visible(false)
  expect_quickfix_visible(true)

  local win_info = get_win_info(get_file_win_id())
  expect.equality(win_info.row, 2)
  expect.equality(win_info.buf_path, file_name)
end
T["setup"]["keymaps"]["select_close_quickfix should open the current item, close the quickfix list"] = function()
  child.lua [[ M.setup { keymaps = { select_close_quickfix = "<cr>", }, } ]]
  child.cmd "copen"
  expect_preview_visible(true)
  expect_quickfix_visible(true)
  child.type_keys "j"
  expect_preview_visible(true)
  expect_quickfix_visible(true)
  child.type_keys "<cr>"
  expect_preview_visible(false)
  expect_quickfix_visible(false)

  expect.equality(get_win_info(get_file_win_id()).row, 2)
end

T["setup"]["keymaps"]["next"] = MiniTest.new_set()
T["setup"]["keymaps"]["next"]["should go to the next item, keep the quickfix preview open"] = function()
  child.lua [[ M.setup { keymaps = { next = { key = "<C-n>", }, }, } ]]
  child.cmd "copen"
  expect_preview_visible(true)
  expect_quickfix_visible(true)

  child.type_keys "<C-n>"
  expect_preview_visible(true)
  expect_quickfix_visible(true)
  expect.equality(get_win_info(get_quickfix_win_id()).row, 2)

  child.type_keys "<C-n>"
  expect_preview_visible(true)
  expect_quickfix_visible(true)
  expect.equality(get_win_info(get_quickfix_win_id()).row, 3)
end
T["setup"]["keymaps"]["next"]["should default circular to true"] = function()
  child.lua [[ M.setup { keymaps = { next = { key = "<C-n>", }, }, } ]]
  child.cmd "copen"
  child.type_keys "<C-n>"
  child.type_keys "<C-n>"
  child.type_keys "<C-n>"
  expect.equality(get_win_info(get_file_win_id()).row, 1)
end
T["setup"]["keymaps"]["next"]["should respect circular as false"] = function()
  child.lua [[ M.setup { keymaps = { next = { key = "<C-n>", circular = false, }, }, } ]]
  child.cmd "copen"
  child.type_keys "<C-n>"
  child.type_keys "<C-n>"
  child.type_keys "<C-n>"
  expect.equality(get_win_info(get_quickfix_win_id()).row, 3)
end

T["setup"]["keymaps"]["prev"] = MiniTest.new_set()
T["setup"]["keymaps"]["prev"]["should go to the next item, keep the quickfix list open"] = function()
  child.lua [[ M.setup { keymaps = { next = { key = "<C-n>", }, prev = { key = "<C-p>", }, }, } ]]
  child.cmd "copen"
  expect_preview_visible(true)
  expect_quickfix_visible(true)

  child.type_keys "<C-n>"
  expect_preview_visible(true)
  expect_quickfix_visible(true)
  expect.equality(get_win_info(get_quickfix_win_id()).row, 2)

  child.type_keys "<C-p>"
  expect_preview_visible(true)
  expect_quickfix_visible(true)
  expect.equality(get_win_info(get_quickfix_win_id()).row, 1)
end
T["setup"]["keymaps"]["prev"]["should default circular to true"] = function()
  child.lua [[ M.setup { keymaps = { prev = { key = "<C-p>", }, }, } ]]
  child.cmd "copen"
  expect_preview_visible(true)
  expect_quickfix_visible(true)

  child.type_keys "<C-p>"
  expect.equality(get_win_info(get_quickfix_win_id()).row, 3)
end
T["setup"]["keymaps"]["prev"]["should respect circular as false"] = function()
  child.lua [[ M.setup { keymaps = { prev = { key = "<C-p>", circular = false }, }, } ]]
  child.cmd "copen"
  expect_preview_visible(true)
  expect_quickfix_visible(true)

  child.type_keys "<C-p>"
  expect.equality(get_win_info(get_quickfix_win_id()).row, 1)
end

T["setup"]["keymaps"]["cnext"] = MiniTest.new_set()
T["setup"]["keymaps"]["cnext"]["should go to the next item, close the quickfix list"] = function()
  child.lua [[ M.setup { keymaps = { cnext = { key = "gn", }, }, } ]]
  child.cmd "copen"
  expect_preview_visible(true)
  expect_quickfix_visible(true)

  child.type_keys "gn"
  expect_preview_visible(false)
  expect_quickfix_visible(true)
  expect.equality(get_win_info(get_file_win_id()).row, 2)

  child.type_keys "gn"
  expect_preview_visible(false)
  expect_quickfix_visible(true)
  expect.equality(get_win_info(get_file_win_id()).row, 3)
end
T["setup"]["keymaps"]["cnext"]["should default circular to true"] = function()
  child.lua [[ M.setup { keymaps = { cnext = { key = "gn", }, }, } ]]
  child.cmd "copen"
  child.type_keys "gn"
  child.type_keys "gn"
  child.type_keys "gn"
  expect.equality(get_win_info(get_file_win_id()).row, 1)
end
T["setup"]["keymaps"]["cnext"]["should respect circular as false"] = function()
  child.lua [[ M.setup { keymaps = { cnext = { key = "gn", circular = false, }, }, } ]]
  child.cmd "copen"
  child.type_keys "gn"
  child.type_keys "gn"
  expect.error(function()
    child.type_keys "gn"
  end)
  expect.equality(get_win_info(get_file_win_id()).row, 3)
end

T["setup"]["keymaps"]["cprev"] = MiniTest.new_set()
T["setup"]["keymaps"]["cprev"]["should go to the prev item, close the quickfix list"] = function()
  child.lua [[ M.setup { keymaps = { cnext = { key = "gn", }, cprev = { key = "gp", }, }, } ]]
  child.cmd "copen"
  expect_preview_visible(true)
  expect_quickfix_visible(true)

  child.type_keys "gn"
  expect_preview_visible(false)
  expect_quickfix_visible(true)
  expect.equality(get_win_info(get_file_win_id()).row, 2)

  child.type_keys "gp"
  expect_preview_visible(false)
  expect_quickfix_visible(true)
  expect.equality(get_win_info(get_file_win_id()).row, 1)
end
T["setup"]["keymaps"]["cprev"]["should default circular to true"] = function()
  child.lua [[ M.setup { keymaps = { cprev = { key = "gp", }, }, } ]]
  child.cmd "copen"
  expect_preview_visible(true)
  expect_quickfix_visible(true)

  child.type_keys "gp"
  expect.equality(get_win_info(get_file_win_id()).row, 3)
end
T["setup"]["keymaps"]["cprev"]["should respect circular as false"] = function()
  child.lua [[ M.setup { keymaps = { cprev = { key = "gp", circular = false }, }, } ]]
  child.cmd "copen"
  expect_preview_visible(true)
  expect_quickfix_visible(true)

  expect.error(function()
    child.type_keys "gp"
  end)
  expect.equality(get_win_info(get_file_win_id()).row, 1)
end

return T
