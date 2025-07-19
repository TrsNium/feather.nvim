local M = {}

M.defaults = {
  window = {
    width = 0.5,  -- 50% width for 5:5 ratio with preview
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
    column_separator = false,  -- Show vertical separator between columns
  },
  preview = {
    enabled = true,      -- Enable preview by default
    position = "auto",    -- "auto", "right", "bottom"
    max_lines = 100,      -- Maximum lines to show in preview
    min_width = 30,       -- Minimum width for preview window
    min_height = 5,       -- Minimum height for preview window
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

M.options = {}  -- Initialize empty

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
  return M.options
end

function M.get()
  -- Return defaults if setup hasn't been called
  if vim.tbl_isempty(M.options) then
    return vim.tbl_deep_extend("force", {}, M.defaults)
  end
  return M.options
end

return M