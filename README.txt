==============================================================================
------------------------------------------------------------------------------
*quickfix-preview.nvim*
A simple preview for quickfix list.

Sample configuration ~
>lua
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
      vim.keymap.set("n", "<C-d>", "<Plug>QuickfixPreviewScrollDown", { buffer = true, })
      vim.keymap.set("n", "<C-u>", "<Plug>QuickfixPreviewScrollUp", { buffer = true, })
    end,
  })
<
------------------------------------------------------------------------------
Performance ~

`quickfix-preview.nvim` considers performance in a few ways:

- Only a single window and buffer is used for the preview - previewing a
  new file updates the content of the existing buffer instead of creating
  a new one.
- The preview is only populated by the first `n` lines of the file, where
  `n` is the current line number + the height of the preview window + the
  `scroll` option. This allows the lines for a single scroll down action
  to be eagerly loaded before the first scroll, while the lines for any
  further scroll down actions are lazily loaded after subsequent scrolls.

------------------------------------------------------------------------------
                                                       *quickfix-preview-config*
Configuration ~

`vim.g.quickfix_preview.open_preview_win_opts` ~
Options passed as the third argument to `vim.api.nvim_open_win` when
opening the preview window.

`vim.g.quickfix_preview.preview_win_opts` ~
Window-level options to apply to the preview window.


==============================================================================
------------------------------------------------------------------------------
                                                  *quickfix-preview-plug-remaps*
Plug remaps ~

`<Plug>QuickfixPreviewToggle` ~
Toggle the quickfix preview.

`<Plug>QuickfixPreviewScrollDown` ~
Scroll the quickfix preview down by |scroll| lines.

`<Plug>QuickfixPreviewScrollUp` ~
Scroll the quickfix preview up by |scroll| lines.

------------------------------------------------------------------------------
                                                     *quickfix-preview-commands*
User commands ~

`QuickfixPreviewClosePreview` ~
Manually close the preview.


 vim:tw=78:ts=8:noet:ft=help:norl: