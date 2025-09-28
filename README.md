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
}

vim.api.nvim_create_autocmd({ "FileType", }, {
  pattern = "qf",
  callback = function()
    vim.keymap.set("n", "o", "<Plug>QuickfixPreviewSelectClosePreview", { buffer = true, })
    vim.keymap.set("n", "<cr>", "<Plug>QuickfixPreviewSelectCloseQuickfix", { buffer = true, })
    vim.keymap.set("n", "t", "<Plug>QuickfixPreviewToggle", { buffer = true, })
    vim.keymap.set("n", "<C-n>", "<Plug>QuickfixPreviewNext", { buffer = true, })
    vim.keymap.set("n", "<C-p>", "<Plug>QuickfixPreviewPrev", { buffer = true, })
  end,
})
```

## Plug remaps

### `QuickfixPreviewToggle`
- Toggle the quickfix preview

### `QuickfixPreviewSelectClosePreview`
- Open the file undor the cursor, keeping the quickfix list open

### `QuickfixPreviewSelectCloseQuickfix`
- Open the file under the cursor, closing the quickfix list

### `QuickfixPreviewNext`
- `:cnext`, preserving focus on the quickfix list

### `QuickfixPreviewPrev`
- `:cprev`, preserving focus on the quickfix list

### `QuickfixPreviewCNext`
- `:cnext`, closing the preview first

### `QuickfixPreviewCPrev`
- `:cprev`, closing the preview first

