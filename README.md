# quickfix-preview.nvim

A simple preview for quickfix list, updates as you move your cursor.

![demo](https://elanmed.dev/nvim-plugins/quickfix-preview.gif)

## Sample configuration

```lua 
require "quickfix-preview".setup {
  -- Options to apply to the preview window. Defaults to an empty table
  preview_win_opts = {
    number = true,
    relativenumber = false,
    signcolumn = "no",
    cursorline = true,
  },
  -- A prefix passed to :pedit, can be used to position the preview window. Defaults to `aboveleft`
  pedit_prefix = "aboveleft", 
  -- A postfix passed to :pedit. Defaults to an empty string
  pedit_postfix = "",
  -- By default, no keymaps are set
  keymaps = {
    -- Toggle the quickfix preview
    -- Buffer-level remap
    toggle = "t",
    -- Open the file undor the cursor, keeping the quickfix list open
    -- Buffer-level remap
    select_close_preview = "o",
    -- Open the file under the cursor, closing the quickfix list
    -- Buffer-level remap
    select_close_quickfix = "<cr>",
    -- :cnext, preserving focus on the quickfix list
    -- Buffer-level remap
    next = {
      key = "<C-n>",
      -- Loop around to the beginning of the quickfix list when reaching the end
      -- `circular` defaults to `true` for `next`, `prev`, `cnext`, and `cprev`
      circular = true,
    },
    -- :cprev, preserving focus on the quickfix list
    -- Buffer-level remap
    prev = { key = "<C-n>", },
    -- :cnext, closing the preview first
    -- Global remap
    cnext = { key = "]q", },
    -- :cprev, closing the preview first
    -- Global remap
    cprev = { key = "[q", },
  },
}
```
