local M = {}

M.defaults = {
  window = {
    width = 0.8,
    height = 0.8,
    border = "rounded",
    position = "center",
  },
  icons = {
    enabled = true,
    folder = "",
    default_file = "",
  },
  features = {
    show_hidden = false,
    auto_close = true,
    split_view = false,  -- Use split view mode
    max_columns = 4,     -- Maximum columns in split view
  },
  keymaps = {
    quit = { "q", "<Esc>" },
    open = { "<CR>", "l" },
    parent = { "h" },
    down = { "j" },
    up = { "k" },
    toggle_hidden = { "." },
    toggle_icons = { "i" },
    toggle_preview = { "p" },
    preview_scroll_down = { "<C-d>" },
    preview_scroll_up = { "<C-u>" },
    home = { "~" },
    search = { "/" },
    help = { "?" },
  },
}

M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
  return M.options
end

function M.get()
  return M.options
end

return M