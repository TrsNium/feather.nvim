local M = {}
local api = vim.api
local fn = vim.fn
local icons = require("feather.icons")
local config = require("feather.config")
local split_view = require("feather.split_view")
local preview = require("feather.preview")
local highlights = require("feather.highlights")

M.state = {
  buf = nil,
  win = nil,
  current_dir = nil,
  files = {},
  selected_line = 1,
  show_hidden = false,
  use_icons = true,
  preview_enabled = false,
}

-- Store whether user has called setup
M._user_setup_done = false

function M.setup(opts)
  opts = opts or {}
  
  -- Mark as user setup if options are provided
  if vim.tbl_count(opts) > 0 then
    M._user_setup_done = true
  end
  
  config.setup(opts)
  local cfg = config.get()
  M.state.show_hidden = cfg.features.show_hidden
  M.state.use_icons = cfg.icons.enabled
  
  -- Setup icons module
  icons.setup()
  
  -- Setup highlights
  highlights.setup()
  
  -- Setup split view
  split_view.setup({
    show_hidden = cfg.features.show_hidden,
    use_icons = cfg.icons.enabled,
    max_columns = cfg.features.max_columns,
  })
end

-- Auto-setup with defaults if not already setup by user
local function ensure_setup()
  if not M._user_setup_done then
    M.setup({})
  end
end

local function get_files(dir)
  local files = {}
  local handle = vim.loop.fs_scandir(dir)
  if handle then
    while true do
      local name, type = vim.loop.fs_scandir_next(handle)
      if not name then break end
      
      if M.state.show_hidden or not name:match("^%.") then
        table.insert(files, {
          name = name,
          type = type,
          path = dir .. "/" .. name
        })
      end
    end
  end
  
  table.sort(files, function(a, b)
    if a.type == b.type then
      return a.name < b.name
    end
    return a.type == "directory" and b.type ~= "directory"
  end)
  
  return files
end

local function render_files(buf, files)
  local lines = {}
  local line_highlights = {}
  local icon_highlights = {}
  
  for i, file in ipairs(files) do
    local line = ""
    local hl_group = highlights.get_highlight(file.type, file.name)
    local icon_start = 0
    
    if M.state.use_icons then
      local icon, icon_hl = icons.get_icon(file.name, file.type == "directory")
      line = icon .. " " .. file.name
      -- Store icon highlight info
      if icon_hl then
        table.insert(icon_highlights, {
          line = i - 1,
          col_start = 0,
          col_end = vim.fn.strwidth(icon),
          hl_group = icon_hl
        })
      end
    else
      local prefix = file.type == "directory" and "▸ " or "  "
      line = prefix .. file.name
    end
    
    if file.type == "directory" then
      line = line .. "/"
    end
    
    table.insert(lines, line)
    table.insert(line_highlights, {i - 1, hl_group})
  end
  
  local modifiable = api.nvim_buf_get_option(buf, "modifiable")
  if not modifiable then
    api.nvim_buf_set_option(buf, "modifiable", true)
  end
  
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Apply highlights
  local ns_id = api.nvim_create_namespace("feather")
  api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
  
  -- Apply line highlights
  for _, hl in ipairs(line_highlights) do
    local line_num, hl_group = hl[1], hl[2]
    api.nvim_buf_add_highlight(buf, ns_id, hl_group, line_num, 0, -1)
  end
  
  -- Apply icon highlights (these take precedence)
  for _, icon_hl in ipairs(icon_highlights) do
    api.nvim_buf_add_highlight(
      buf,
      ns_id,
      icon_hl.hl_group,
      icon_hl.line,
      icon_hl.col_start,
      icon_hl.col_end
    )
  end
  
  if not modifiable then
    api.nvim_buf_set_option(buf, "modifiable", false)
  end
end

local function create_float_window()
  local cfg = config.get()
  local width = math.floor(vim.o.columns * cfg.window.width)
  local height = math.floor(vim.o.lines * cfg.window.height)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  local buf = api.nvim_create_buf(false, true)
  local win = api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = cfg.window.border,
    title = " Feather ",
    title_pos = "center",
  })
  
  return buf, win
end

local function setup_keymaps(buf)
  local opts = { noremap = true, silent = true, buffer = buf }
  
  vim.keymap.set("n", "q", function() M.close() end, opts)
  vim.keymap.set("n", "<Esc>", function() M.close() end, opts)
  vim.keymap.set("n", "<CR>", function() M.open_selection() end, opts)
  vim.keymap.set("n", "l", function() M.open_selection() end, opts)
  vim.keymap.set("n", "h", function() M.go_parent() end, opts)
  vim.keymap.set("n", "j", function() M.move_cursor(1) end, opts)
  vim.keymap.set("n", "k", function() M.move_cursor(-1) end, opts)
  vim.keymap.set("n", ".", function() M.toggle_hidden() end, opts)
  vim.keymap.set("n", "i", function() M.toggle_icons() end, opts)
  vim.keymap.set("n", "~", function() M.go_home() end, opts)
  vim.keymap.set("n", "/", function() M.search() end, opts)
  vim.keymap.set("n", "?", function() M.show_help() end, opts)
  vim.keymap.set("n", "p", function() M.toggle_preview() end, opts)
  vim.keymap.set("n", "<C-d>", function() M.preview_scroll(10) end, opts)
  vim.keymap.set("n", "<C-u>", function() M.preview_scroll(-10) end, opts)
end

function M.open_selection()
  local line = api.nvim_win_get_cursor(M.state.win)[1]
  local file = M.state.files[line]
  if not file then return end
  
  if file.type == "directory" then
    M.state.current_dir = file.path
    M.refresh()
  else
    M.close()
    vim.cmd("edit " .. fn.fnameescape(file.path))
  end
end

function M.go_parent()
  local parent = fn.fnamemodify(M.state.current_dir, ":h")
  if parent ~= M.state.current_dir then
    M.state.current_dir = parent
    M.refresh()
  end
end

function M.move_cursor(direction)
  local current_line = api.nvim_win_get_cursor(M.state.win)[1]
  local new_line = current_line + direction
  local line_count = api.nvim_buf_line_count(M.state.buf)
  
  if new_line >= 1 and new_line <= line_count then
    api.nvim_win_set_cursor(M.state.win, {new_line, 0})
    
    -- Update preview if enabled
    if M.state.preview_enabled then
      local file = M.state.files[new_line]
      if file then
        preview.update(file.path, M.state.win)
      end
    end
  end
end

function M.refresh()
  if not M.state.buf or not api.nvim_buf_is_valid(M.state.buf) then
    return
  end
  
  M.state.files = get_files(M.state.current_dir)
  render_files(M.state.buf, M.state.files)
  
  local title = " Feather: " .. fn.fnamemodify(M.state.current_dir, ":~") .. " "
  api.nvim_win_set_config(M.state.win, { title = title })
  
  api.nvim_win_set_cursor(M.state.win, {1, 0})
end

function M.open()
  ensure_setup()
  local cfg = config.get()
  -- Debug: print current config
  -- vim.notify("Split view enabled: " .. tostring(cfg.features.split_view), vim.log.levels.INFO)
  if cfg.features.split_view then
    split_view.open()
  else
    if M.state.win and api.nvim_win_is_valid(M.state.win) then
      return
    end
    
    M.state.current_dir = fn.getcwd()
    M.state.buf, M.state.win = create_float_window()
    
    api.nvim_buf_set_option(M.state.buf, "buftype", "nofile")
    api.nvim_buf_set_option(M.state.buf, "bufhidden", "wipe")
    api.nvim_buf_set_option(M.state.buf, "modifiable", false)
    api.nvim_win_set_option(M.state.win, "cursorline", true)
    api.nvim_win_set_option(M.state.win, "winhighlight", "Normal:Normal,NormalFloat:Normal,FloatBorder:Normal")
    
    setup_keymaps(M.state.buf)
    M.refresh()
  end
end

function M.close()
  local cfg = config.get()
  if cfg.features.split_view then
    split_view.close()
  else
    preview.close()  -- Close preview window
    if M.state.win and api.nvim_win_is_valid(M.state.win) then
      api.nvim_win_close(M.state.win, true)
    end
    M.state.buf = nil
    M.state.win = nil
    M.state.preview_enabled = false
  end
end

function M.toggle()
  ensure_setup()
  local cfg = config.get()
  if cfg.features.split_view then
    split_view.toggle()
  else
    if M.state.win and api.nvim_win_is_valid(M.state.win) then
      M.close()
    else
      M.open()
    end
  end
end

function M.toggle_hidden()
  M.state.show_hidden = not M.state.show_hidden
  M.refresh()
end

function M.toggle_icons()
  M.state.use_icons = not M.state.use_icons
  M.refresh()
end

function M.go_home()
  M.state.current_dir = vim.fn.expand("~")
  M.refresh()
end

function M.search()
  vim.ui.input({ prompt = "Search: " }, function(input)
    if input and input ~= "" then
      for i, file in ipairs(M.state.files) do
        if file.name:lower():find(input:lower(), 1, true) then
          api.nvim_win_set_cursor(M.state.win, {i, 0})
          break
        end
      end
    end
  end)
end

function M.show_help()
  local help_text = {
    "Feather.nvim Help",
    "",
    "Navigation:",
    "  j/k     - Move cursor down/up",
    "  h       - Go to parent directory", 
    "  l/<CR>  - Open file/directory",
    "  ~       - Go to home directory",
    "",
    "Features:",
    "  .       - Toggle hidden files",
    "  i       - Toggle icons",
    "  p       - Toggle file preview",
    "  /       - Search files",
    "  ?       - Show this help",
    "",
    "Preview:",
    "  <C-d>   - Scroll preview down",
    "  <C-u>   - Scroll preview up",
    "",
    "Exit:",
    "  q/<Esc> - Close Feather",
  }
  
  vim.notify(table.concat(help_text, "\n"), vim.log.levels.INFO, { title = "Feather Help" })
end

function M.toggle_preview()
  if not M.state.win or not api.nvim_win_is_valid(M.state.win) then
    return
  end
  
  M.state.preview_enabled = not M.state.preview_enabled
  
  if M.state.preview_enabled then
    local line = api.nvim_win_get_cursor(M.state.win)[1]
    local file = M.state.files[line]
    if file then
      preview.show(file.path, M.state.win, "auto")
    end
  else
    preview.close()
  end
end

function M.preview_scroll(lines)
  if M.state.preview_enabled then
    preview.scroll(lines)
  end
end

return M