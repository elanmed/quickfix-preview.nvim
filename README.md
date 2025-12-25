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

## Performance

`quickfix-preview.nvim` considers performance in a few ways:

- Only a single window and buffer is used for the preview - previewing a new file updates the content of the existing buffer instead of creating a new one.
- The preview is only populated by the first `n` lines of the file, where `n` is the current line number + the height of the preview window + the `scroll` option. This allows the lines for a single scroll down action to be eagerly loaded before the first scroll, while the lines for any further scroll down actions are lazily loaded after subsequent scrolls.

## Configuration options

#### `vim.g.quickfix_preview.open_preview_win_opts`

- Options passed as the third argument to `vim.api.nvim_open_win` when opening the preview options

#### `vim.g.quickfix_preview.preview_win_opts`

- Window-level options to apply to the preview window

## Plug remaps

#### `<Plug>QuickfixPreviewToggle`

- Toggle the quickfix preview

#### `<Plug>QuickfixPreviewScrollUp`

- Scroll the quickfix preview up by `vim.wo.scroll` lines

#### `<Plug>QuickfixPreviewScrollDown`

- Scroll the quickfix preview down by `vim.wo.scroll` lines

## User commands

#### `QuickfixPreviewClosePreview`

- Manually close the preview
