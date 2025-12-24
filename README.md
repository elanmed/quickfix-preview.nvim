# quickfix-preview.nvim

A simple preview for quickfix list

![demo](https://elanmed.dev/nvim-plugins/quickfix-preview.png)

## Sample configuration

```lua
vim.g.quickfix_preview = {
  -- defaults:
  open_preview_win_opts = {
    style = "minimal",
    split = "right",
    width = math.floor(vim.o.columns / 2),
  },
  preview_win_opts = {
    cursorline = true,
    number = true,
  }
}

vim.api.nvim_create_autocmd({ "FileType", }, {
  pattern = "qf",
  callback = function()
    vim.keymap.set("n", "t", "<Plug>QuickfixPreviewToggle", { buffer = true, })
  end,
})
```

## Configuration options

#### `vim.g.quickfix_preview.open_preview_win_opts`

- Options passed as the third argument to `vim.api.nvim_open_win` when opening the preview options

#### `vim.g.quickfix_preview.preview_win_opts`

- Window-level options to apply to the preview window

## Plug remaps

#### `<Plug>QuickfixPreviewToggle`

- Toggle the quickfix preview

## User commands

#### `QuickfixPreviewClosePreview`

- Manually close the preview

## TODO

- Support scrolling the preview
