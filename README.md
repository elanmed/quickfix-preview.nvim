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
    toggle = "t",
    -- Open the file undor the cursor, keeping the quickfix list open
    open = "o",
    -- Open the file under the cursor, closing the quickfix list
    openc = "<cr>",
    -- :cnext, preserving focus on the quickfix list
    next = {
      key = "<C-n>",
      -- Loop around to the beginning of the quickfix list when reaching the end
      -- `circular` defaults to `true` for `next`, `prev`, `cnext`, and `cprev`
      circular = true,
    },
    -- :cprev, preserving focus on the quickfix list
    prev = { key = "<C-n>", },
    -- :cnext, closing the preview first
    cnext = { key = "]q", },
    -- :cprev, closing the preview first
    cprev = { key = "[q", },
  },
}
```

## Exported functions

By default: 
- The preview will open when the quickfix list is opened
    - Unless the `toggle` keymap was invoked
- The preview will update When moving the cursor up or down to another item in the quickfix list
    - Unless the `toggle` keymap was invoked
- The preview will close when the quickfix list is closed

To override this behavior, the following functions are exposed:

### `open`
Opens the quickfix preview.

Accepts no arguments, returns no value.

### `close`
Closes the quickfix preview.

Accepts no arguments, returns no value.

### `set_preview_disabled`
Sets if the quickfix preview is disabled.

Accepts a single argument `is_disabled`, returns no value.

## TODO
- [ ] pedit_prefix, pedit_postfix tests
- [x] Demo gif
- [ ] Allow window-level options through the setup config
- [x] Support a `pedit` prefix like `aboveleft` through the setup config
