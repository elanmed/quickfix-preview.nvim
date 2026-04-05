vim.cmd [[let &rtp.=','.getcwd()]]
vim.cmd "set rtp+=deps/mini.nvim"

require "mini.doc".setup {
  -- Handle both '---@xxx' and '--- @xxx' (formatter adds a space after ---)
  annotation_extractor = function(l)
    local s, e, id = string.find(l, "^%-%-%- (@%S+) ?")
    if s then return s, e, id end
    return string.find(l, "^%-%-%-(%S*) ?")
  end,
}

MiniDoc.generate(
  { "lua/quickfix-preview/class.lua", "after/ftplugin/qf.lua", },
  "doc/quickfix-preview.txt"
)
