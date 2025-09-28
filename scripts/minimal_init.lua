-- https://github.com/echasnovski/mini.nvim/blob/main/TESTING.md#file-organization
vim.cmd [[let &rtp.=','.getcwd()]]

if #vim.api.nvim_list_uis() == 0 then
  vim.cmd "set rtp+=deps/mini.nvim"
  vim.cmd "set rtp+=deps/nvim-treesitter"
  vim.cmd "set rtp+=after/"
  require "mini.test".setup()
end
