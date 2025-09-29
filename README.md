# quickfix-preview.nvim

A simple preview for quickfix list, updates as you move your cursor.

![demo](https://elanmed.dev/nvim-plugins/quickfix-preview.gif)

## Sample configuration

```lua 
vim.g.quickfix_preview = {
  preview_win_opts = {
    number = true,
    relativenumber = false,
    signcolumn = "no",
    cursorline = true,
  },
  pedit_prefix = "aboveleft",
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

## Configuration options

#### `vim.g.quickfix_preview.preview_win_opts`
- Options to apply to the preview window. Defaults to an empty table

#### `vim.g.quickfix_preview.pedit_prefix`
- A prefix passed to :pedit, can be used to position the preview window. Defaults to `aboveleft`

#### `vim.g.quickfix_preview.pedit_postfix`
- A postfix passed to :pedit. Defaults to an empty string

## Plug remaps

#### `<Plug>QuickfixPreviewToggle`
- Toggle the quickfix preview

#### `<Plug>QuickfixPreviewSelectClosePreview`
- Open the file undor the cursor, keeping the quickfix list open

#### `<Plug>QuickfixPreviewSelectCloseQuickfix`
- Open the file under the cursor, closing the quickfix list

#### `<Plug>QuickfixPreviewNext`
- `:cnext`, preserving focus on the quickfix list

#### `<Plug>QuickfixPreviewPrev`
- `:cprev`, preserving focus on the quickfix list

#### `<Plug>QuickfixPreviewCNext`
- `:cnext`, closing the preview first

#### `<Plug>QuickfixPreviewCPrev`
- `:cprev`, closing the preview first

