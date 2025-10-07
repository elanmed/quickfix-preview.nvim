require "mini.test".setup()

local expect = MiniTest.expect

local child = MiniTest.new_child_neovim()
local file_name = "test_file.lua"

local function get_preview_win_id()
  for _, winnr in ipairs(child.api.nvim_list_wins()) do
    local bufnr = child.api.nvim_win_get_buf(winnr)
    if child.api.nvim_get_option_value("filetype", { buf = bufnr, }) == "quickfix-preview" then
      return winnr
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

--- @param win_id number|nil
local function get_win_info(win_id)
  local row, col_0_indexed = unpack(child.api.nvim_win_get_cursor(win_id))
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

T["initialization"] = MiniTest.new_set()
T["initialization"]["autocommands"] = MiniTest.new_set()
T["initialization"]["autocommands"]["should open the preview on copen"] = function()
  child.cmd "copen"
  expect_preview_visible(true)
  local win_info = get_win_info(get_preview_win_id())
  expect.equality(win_info.row, 1)
end
T["initialization"]["autocommands"]["should refresh the preview on cursor move"] = function()
  child.cmd "copen"
  child.type_keys "j"
  expect_preview_visible(true)
  local win_info = get_win_info(get_preview_win_id())
  expect.equality(win_info.row, 2)
end
T["initialization"]["autocommands"]["should close the preview on cclose"] = function()
  child.cmd "copen"
  expect_preview_visible(true)
  child.cmd "cclose"
  expect_preview_visible(false)
end

T["configuration"] = MiniTest.new_set()
T["configuration"]["preview_win_opts"] = function()
  child.g.quickfix_preview = {
    preview_win_opts = { number = false, cursorline = false, },
  }
  child.cmd "copen"
  expect_preview_visible(true)
  local preview_win_id = get_preview_win_id()
  local number_opt = child.api.nvim_get_option_value("number", { win = preview_win_id, })
  expect.equality(number_opt, false) -- defaults to `true`
  local cursorline_opt = child.api.nvim_get_option_value("cursorline", { win = preview_win_id, })
  expect.equality(cursorline_opt, false) -- defaults to `true`
end

T["keymaps"] = MiniTest.new_set()
T["keymaps"]["toggle should toggle the preview"] = function()
  child.lua [[
  vim.keymap.set("n", "t", "<Plug>QuickfixPreviewToggle")
  ]]
  child.cmd "copen"
  expect_preview_visible(true)
  child.type_keys "t"
  expect_preview_visible(false)
  child.type_keys "t"
  expect_preview_visible(true)
end

return T
