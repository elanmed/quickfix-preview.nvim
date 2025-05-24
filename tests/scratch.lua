-- vim.restart { "-u", "scripts/minimal_init.lua", }
-- vim.bo.readonly = false
-- vim.lua [[M = require('quickfix-preview')]]

local file_name = "test_sample_file.txt"
local lines = { "alpha", "bravo", "charlie", }
vim.fn.writefile(lines, file_name)
vim.cmd("edit " .. file_name)

local bufnr = vim.api.nvim_get_current_buf()

local qf_items = {}
for index, line in pairs(lines) do
  table.insert(qf_items, {
    bufnr = bufnr,
    lnum = index,
    col = index,
    text = line,
  })
end
vim.fn.setqflist(qf_items, "r")
