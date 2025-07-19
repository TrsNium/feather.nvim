local M = {}
local api = vim.api
local fn = vim.fn
local icons = require("feather.icons")
local config = require("feather.config")
local highlights = require("feather.highlights")
local preview = require("feather.preview")

M.state = {
  -- Main container
  container_win = nil,
  container_buf = nil,
  
  -- Left pane (file explorer)
  explorer_win = nil,
  explorer_buf = nil,
  
  -- Right pane (preview)
  preview_win = nil,
  preview_buf = nil,
  
  -- Separator window
  separator_win = nil,
  
  -- Explorer state
  current_dir = nil,
  files = {},
  cursor = 1,
  
  -- Settings
  show_hidden = false,
  use_icons = true,
  preview_enabled = true,  -- Start with preview enabled by default
}

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
  
  -- Sort: directories first, then files
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
  local ns_id = api.nvim_create_namespace("feather_split")
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

local function update_preview()
  if not M.state.preview_enabled or not M.state.preview_win then
    return
  end
  
  local file = M.state.files[M.state.cursor]
  if not file then
    return
  end
  
  -- Use the preview module to render content
  if M.state.preview_buf and api.nvim_buf_is_valid(M.state.preview_buf) then
    preview.render_preview(M.state.preview_buf, file.path)
  end
end

local function setup_keymaps(buf)
  local opts = { noremap = true, silent = true, buffer = buf }
  
  vim.keymap.set("n", "j", function() M.move_cursor(1) end, opts)
  vim.keymap.set("n", "k", function() M.move_cursor(-1) end, opts)
  vim.keymap.set("n", "l", function() M.open_selection() end, opts)
  vim.keymap.set("n", "<CR>", function() M.open_selection() end, opts)
  vim.keymap.set("n", "h", function() M.go_parent() end, opts)
  vim.keymap.set("n", "-", function() M.go_parent() end, opts)
  vim.keymap.set("n", "q", function() M.close() end, opts)
  vim.keymap.set("n", "<Esc>", function() M.close() end, opts)
  vim.keymap.set("n", ".", function() M.toggle_hidden() end, opts)
  vim.keymap.set("n", "i", function() M.toggle_icons() end, opts)
  vim.keymap.set("n", "?", function() M.show_help() end, opts)
  vim.keymap.set("n", "p", function() M.toggle_preview() end, opts)
  vim.keymap.set("n", "<C-d>", function() M.preview_scroll(10) end, opts)
  vim.keymap.set("n", "<C-u>", function() M.preview_scroll(-10) end, opts)
  vim.keymap.set("n", "~", function() M.go_home() end, opts)
  vim.keymap.set("n", "/", function() M.search() end, opts)
end

function M.move_cursor(direction)
  local new_pos = M.state.cursor + direction
  local max_pos = #M.state.files
  
  if new_pos >= 1 and new_pos <= max_pos then
    M.state.cursor = new_pos
    if M.state.explorer_win and api.nvim_win_is_valid(M.state.explorer_win) then
      api.nvim_win_set_cursor(M.state.explorer_win, {new_pos, 0})
    end
    update_preview()
  end
end

function M.open_selection()
  local file = M.state.files[M.state.cursor]
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

function M.go_home()
  M.state.current_dir = vim.fn.expand("~")
  M.refresh()
end

function M.refresh()
  if not M.state.explorer_buf or not api.nvim_buf_is_valid(M.state.explorer_buf) then
    return
  end
  
  M.state.files = get_files(M.state.current_dir)
  M.state.cursor = 1
  render_files(M.state.explorer_buf, M.state.files)
  
  -- Update window title
  local title = " Feather - " .. fn.fnamemodify(M.state.current_dir, ":~") .. " "
  if M.state.container_win and api.nvim_win_is_valid(M.state.container_win) then
    api.nvim_win_set_config(M.state.container_win, { title = title })
  end
  
  -- Set cursor to first line
  if M.state.explorer_win and api.nvim_win_is_valid(M.state.explorer_win) then
    api.nvim_win_set_cursor(M.state.explorer_win, {1, 0})
  end
  
  update_preview()
end

function M.update_layout()
  if not M.state.container_win or not api.nvim_win_is_valid(M.state.container_win) then
    return
  end
  
  local cfg = config.get()
  local width = math.floor(vim.o.columns * cfg.window.width)
  local height = math.floor(vim.o.lines * cfg.window.height)
  
  if M.state.preview_enabled then
    -- 2-pane layout
    local explorer_width = math.floor(width * 0.5)
    local preview_width = width - explorer_width - 1
    
    -- Update explorer window
    if M.state.explorer_win and api.nvim_win_is_valid(M.state.explorer_win) then
      api.nvim_win_set_config(M.state.explorer_win, {
        width = explorer_width,
        height = height - 2,
      })
    end
    
    -- Show/create separator
    if M.state.separator_win and api.nvim_win_is_valid(M.state.separator_win) then
      api.nvim_win_set_config(M.state.separator_win, {
        col = explorer_width,
        height = height - 2,
      })
    else
      -- Create separator
      local sep_buf = api.nvim_create_buf(false, true)
      api.nvim_buf_set_option(sep_buf, "buftype", "nofile")
      api.nvim_buf_set_option(sep_buf, "modifiable", false)
      
      M.state.separator_win = api.nvim_open_win(sep_buf, false, {
        relative = "win",
        win = M.state.container_win,
        width = 1,
        height = height - 2,
        row = 1,
        col = explorer_width,
        style = "minimal",
        border = "none",
        focusable = false,
      })
      
      -- Fill separator with vertical lines
      local sep_lines = {}
      for _ = 1, height - 2 do
        table.insert(sep_lines, "│")
      end
      api.nvim_buf_set_option(sep_buf, "modifiable", true)
      api.nvim_buf_set_lines(sep_buf, 0, -1, false, sep_lines)
      api.nvim_buf_set_option(sep_buf, "modifiable", false)
      api.nvim_win_set_option(M.state.separator_win, "winhighlight", "Normal:Comment")
    end
    
    -- Show/create preview window
    if M.state.preview_win and api.nvim_win_is_valid(M.state.preview_win) then
      api.nvim_win_set_config(M.state.preview_win, {
        width = preview_width - 1,
        height = height - 2,
        col = explorer_width + 1,
      })
    else
      -- Create preview pane
      M.state.preview_buf = api.nvim_create_buf(false, true)
      api.nvim_buf_set_option(M.state.preview_buf, "buftype", "nofile")
      api.nvim_buf_set_option(M.state.preview_buf, "bufhidden", "wipe")
      api.nvim_buf_set_option(M.state.preview_buf, "modifiable", true)
      
      M.state.preview_win = api.nvim_open_win(M.state.preview_buf, false, {
        relative = "win",
        win = M.state.container_win,
        width = preview_width - 1,
        height = height - 2,
        row = 1,
        col = explorer_width + 1,
        style = "minimal",
        border = "none",
        focusable = false,
      })
      
      api.nvim_win_set_option(M.state.preview_win, "number", true)
      api.nvim_win_set_option(M.state.preview_win, "wrap", true)
      api.nvim_win_set_option(M.state.preview_win, "cursorline", false)
      
      -- Store preview state for preview module
      preview.state.win = M.state.preview_win
      preview.state.buf = M.state.preview_buf
    end
    
    update_preview()
  else
    -- 1-pane layout
    if M.state.explorer_win and api.nvim_win_is_valid(M.state.explorer_win) then
      api.nvim_win_set_config(M.state.explorer_win, {
        width = width - 2,
        height = height - 2,
      })
    end
    
    -- Hide separator
    if M.state.separator_win and api.nvim_win_is_valid(M.state.separator_win) then
      api.nvim_win_close(M.state.separator_win, true)
      M.state.separator_win = nil
    end
    
    -- Hide preview
    if M.state.preview_win and api.nvim_win_is_valid(M.state.preview_win) then
      api.nvim_win_close(M.state.preview_win, true)
      M.state.preview_win = nil
      preview.state.win = nil
      preview.state.buf = nil
    end
  end
end

function M.open()
  if M.state.container_win and api.nvim_win_is_valid(M.state.container_win) then
    return
  end
  
  local cfg = config.get()
  local width = math.floor(vim.o.columns * cfg.window.width)
  local height = math.floor(vim.o.lines * cfg.window.height)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  -- Create container
  M.state.container_buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_option(M.state.container_buf, "buftype", "nofile")
  
  M.state.container_win = api.nvim_open_win(M.state.container_buf, false, {
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
  
  -- Set window highlight
  api.nvim_win_set_option(M.state.container_win, "winhighlight", "Normal:Normal,NormalFloat:Normal,FloatBorder:Normal")
  
  -- Create explorer pane
  M.state.explorer_buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_option(M.state.explorer_buf, "buftype", "nofile")
  api.nvim_buf_set_option(M.state.explorer_buf, "bufhidden", "wipe")
  
  local explorer_width = M.state.preview_enabled and math.floor(width * 0.5) or width - 2
  M.state.explorer_win = api.nvim_open_win(M.state.explorer_buf, true, {
    relative = "win",
    win = M.state.container_win,
    width = explorer_width,
    height = height - 2,
    row = 1,
    col = 0,
    style = "minimal",
    border = "none",
  })
  
  api.nvim_win_set_option(M.state.explorer_win, "cursorline", true)
  api.nvim_win_set_option(M.state.explorer_win, "wrap", false)
  
  -- Setup keymaps
  setup_keymaps(M.state.explorer_buf)
  
  -- Initialize
  M.state.current_dir = fn.getcwd()
  M.refresh()
  
  -- Create preview if enabled
  if M.state.preview_enabled then
    M.update_layout()
  end
  
  -- Focus on explorer
  api.nvim_set_current_win(M.state.explorer_win)
end

function M.close()
  -- Close preview state
  preview.state.win = nil
  preview.state.buf = nil
  
  -- Close all windows
  local windows = {
    M.state.explorer_win,
    M.state.preview_win,
    M.state.separator_win,
    M.state.container_win
  }
  
  for _, win in ipairs(windows) do
    if win and api.nvim_win_is_valid(win) then
      api.nvim_win_close(win, true)
    end
  end
  
  -- Reset state
  M.state.container_win = nil
  M.state.container_buf = nil
  M.state.explorer_win = nil
  M.state.explorer_buf = nil
  M.state.preview_win = nil
  M.state.preview_buf = nil
  M.state.separator_win = nil
end

function M.toggle()
  if M.state.container_win and api.nvim_win_is_valid(M.state.container_win) then
    M.close()
  else
    M.open()
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

function M.toggle_preview()
  M.state.preview_enabled = not M.state.preview_enabled
  M.update_layout()
  
  if not M.state.preview_enabled then
    vim.notify("Preview disabled", vim.log.levels.INFO)
  else
    vim.notify("Preview enabled", vim.log.levels.INFO)
  end
end

function M.preview_scroll(lines)
  if M.state.preview_enabled and M.state.preview_win and api.nvim_win_is_valid(M.state.preview_win) then
    local current_line = api.nvim_win_get_cursor(M.state.preview_win)[1]
    local new_line = math.max(1, current_line + lines)
    pcall(api.nvim_win_set_cursor, M.state.preview_win, {new_line, 0})
  end
end

function M.search()
  vim.ui.input({ prompt = "Search: " }, function(input)
    if input and input ~= "" then
      for i, file in ipairs(M.state.files) do
        if file.name:lower():find(input:lower(), 1, true) then
          M.state.cursor = i
          if M.state.explorer_win and api.nvim_win_is_valid(M.state.explorer_win) then
            api.nvim_win_set_cursor(M.state.explorer_win, {i, 0})
          end
          update_preview()
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
    "  h/-     - Go to parent directory",
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

function M.setup(opts)
  M.state.show_hidden = opts.show_hidden or false
  M.state.use_icons = opts.use_icons == nil and true or opts.use_icons
  
  -- Setup highlights if not already done
  local has_highlights = pcall(require, "feather.highlights")
  if has_highlights then
    require("feather.highlights").setup()
  end
end

return M