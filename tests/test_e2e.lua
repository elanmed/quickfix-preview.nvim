local expect = MiniTest.expect

local child = MiniTest.new_child_neovim()

local function get_preview_win_id()
  for _, win_id in ipairs(child.api.nvim_list_wins()) do
    if child.api.nvim_get_option_value("previewwindow", { win = win_id, }) then
      return win_id
    end
  end
  return nil
end

--- @param preview_win_id number
local function get_win_info(preview_win_id)
  local row, col_0_indexed = table.unpack(child.api.nvim_win_get_cursor(preview_win_id))
  local col = col_0_indexed + 1

  local bufnr = child.api.nvim_win_get_buf(preview_win_id)
  local buf_path = vim.fs.basename(child.api.nvim_buf_get_name(bufnr))

  return {
    row = row,
    col = col,
    buf_path = buf_path,
  }
end

local file_name = "tests/test_sample_file.txt"
local T = MiniTest.new_set {
  hooks = {
    pre_case = function()
      child.restart { "-u", "scripts/minimal_init.lua", }
      child.bo.readonly = false
      child.lua [[M = require('quickfix-preview').setup()]]

      local lines = { "alpha", "bravo", "charlie", }
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
T["setup"]["autocommands"] = MiniTest.new_set()
T["setup"]["autocommands"]["should open the preview on copen"] = function()
  child.cmd "copen"
  local preview_win_id = get_preview_win_id()
  expect.no_equality(preview_win_id, nil)
  local win_info = get_win_info(preview_win_id)
  expect.equality(win_info.row, 1)
  expect.equality(win_info.buf_path, "test_sample_file.txt")
end
T["setup"]["autocommands"]["should refresh the preview on cursor move"] = function()
  child.cmd "copen"
  child.type_keys "j"
  local preview_win_id = get_preview_win_id()
  expect.no_equality(preview_win_id, nil)
  local win_info = get_win_info(preview_win_id)
  expect.equality(win_info.row, 2)
  expect.equality(win_info.buf_path, "test_sample_file.txt")
end
T["setup"]["autocommands"]["should close the preview on cclose"] = function()
  child.cmd "copen"
  expect.no_equality(get_preview_win_id(), nil)
  child.cmd "cclose"
  expect.equality(get_preview_win_id(), nil)
end

T["setup"]["keymaps"] = MiniTest.new_set()
T["setup"]["keymaps"]["should set no keymaps by default"] = function() end
T["setup"]["keymaps"]["toggle should toggle the preview"] = function() end
T["setup"]["keymaps"]["open should open the current item, keep the quickfix list open"] = function() end
T["setup"]["keymaps"]["openc should open the current item, close the quickfix list"] = function() end

T["setup"]["keymaps"]["next"] = MiniTest.new_set()
T["setup"]["keymaps"]["next"]["should go to the next item, keep the quickfix list open"] = function() end
T["setup"]["keymaps"]["next"]["should default circular to true"] = function() end
T["setup"]["keymaps"]["next"]["should respect circular as false"] = function() end

T["setup"]["keymaps"]["prev"] = MiniTest.new_set()
T["setup"]["keymaps"]["prev"]["should go to the next item, keep the quickfix list open"] = function() end
T["setup"]["keymaps"]["prev"]["should default circular to true"] = function() end
T["setup"]["keymaps"]["prev"]["should respect circular as false"] = function() end

T["setup"]["keymaps"]["cnext"] = MiniTest.new_set()
T["setup"]["keymaps"]["cnext"]["should go to the next item, close the quickfix list"] = function() end
T["setup"]["keymaps"]["cnext"]["should default circular to true"] = function() end
T["setup"]["keymaps"]["cnext"]["should respect circular as false"] = function() end

T["setup"]["keymaps"]["cprev"] = MiniTest.new_set()
T["setup"]["keymaps"]["cprev"]["should go to the prev item, close the quickfix list"] = function() end
T["setup"]["keymaps"]["cprev"]["should default circular to true"] = function() end
T["setup"]["keymaps"]["cprev"]["should respect circular as false"] = function() end

return T
