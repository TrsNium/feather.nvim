local M = {}
local api = vim.api
local fn = vim.fn
local icons = require("feather.icons")
local config = require("feather.config")
local highlights = require("feather.highlights")
local preview = require("feather.preview")

M.state = {
  container_win = nil,
  container_buf = nil,
  columns = {},  -- Array of { win, buf, dir, files, cursor }
  active_col = 1,
  show_hidden = false,
  use_icons = true,
  max_columns = 3,  -- Reduce max columns to make room for preview
  preview_enabled = nil,  -- Will be set from config
  column_separator = true,
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
  
  table.sort(files, function(a, b)
    if a.type == b.type then
      return a.name < b.name
    end
    return a.type == "directory" and b.type ~= "directory"
  end)
  
  return files
end

local function render_files(buf, files, is_active)
  local lines = {}
  local line_highlights = {}
  
  for i, file in ipairs(files) do
    local line = ""
    local hl_group = highlights.get_highlight(file.type, file.name)
    
    if M.state.use_icons then
      local icon, icon_hl = icons.get_icon(file.name, file.type == "directory")
      line = icon .. " " .. file.name
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
  
  for _, hl in ipairs(line_highlights) do
    local line_num, hl_group = hl[1], hl[2]
    api.nvim_buf_add_highlight(buf, ns_id, hl_group, line_num, 0, -1)
  end
  
  if not modifiable then
    api.nvim_buf_set_option(buf, "modifiable", false)
  end
end

local function create_column_window(parent_win, col_index, total_cols, container_width, container_height)
  local col_width = math.floor(container_width / total_cols)
  local col_start = (col_index - 1) * col_width
  
  -- Adjust width and position based on column separator setting
  local width_adjustment = 0
  local border_style = "none"
  
  if M.state.column_separator and col_index < total_cols then
    -- Add right border for all columns except the last
    border_style = { "", "", "", "│", "", "", "", "│" }
    width_adjustment = 1  -- Account for border
  end
  
  local buf = api.nvim_create_buf(false, true)
  
  -- Set buffer options before creating window
  api.nvim_buf_set_option(buf, "buftype", "nofile")
  api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  api.nvim_buf_set_option(buf, "modifiable", false)
  
  local win = api.nvim_open_win(buf, false, {
    relative = "win",
    win = parent_win,
    width = col_width - 1 - width_adjustment,  -- Adjust for separator
    height = container_height - 2,  -- Leave space for container border
    row = 1,
    col = col_start,
    style = "minimal",
    border = border_style,
    focusable = true,  -- Ensure window is focusable
  })
  
  -- Set window options
  api.nvim_win_set_option(win, "cursorline", true)
  api.nvim_win_set_option(win, "wrap", false)
  api.nvim_win_set_option(win, "winhighlight", "Normal:Normal")
  
  return buf, win
end

-- Forward declarations
local setup_column_keymaps


local function update_title()
  if M.state.container_win and api.nvim_win_is_valid(M.state.container_win) then
    local col = M.state.columns[M.state.active_col]
    if col then
      local title = " Feather - " .. fn.fnamemodify(col.dir, ":~") .. " "
      api.nvim_win_set_config(M.state.container_win, { title = title, title_pos = "center" })
    end
  end
end

local function update_column_highlights()
  for i, col in ipairs(M.state.columns) do
    if api.nvim_win_is_valid(col.win) then
      if i == M.state.active_col then
        api.nvim_win_set_option(col.win, "winhl", "Normal:Normal,CursorLine:Visual")
      else
        api.nvim_win_set_option(col.win, "winhl", "Normal:Comment,CursorLine:CursorLine")
      end
    end
  end
  -- Update title when column focus changes
  update_title()
end

local function add_column(dir)
  if #M.state.columns >= M.state.max_columns then
    -- Remove first column
    local first_col = table.remove(M.state.columns, 1)
    if api.nvim_win_is_valid(first_col.win) then
      api.nvim_win_close(first_col.win, true)
    end
  end
  
  local container_width = api.nvim_win_get_width(M.state.container_win)
  local container_height = api.nvim_win_get_height(M.state.container_win)
  
  -- Recalculate all column positions
  for i, col in ipairs(M.state.columns) do
    if api.nvim_win_is_valid(col.win) then
      api.nvim_win_close(col.win, true)
    end
  end
  
  -- Create new column
  local files = get_files(dir)
  local buf, win = create_column_window(
    M.state.container_win,
    #M.state.columns + 1,
    #M.state.columns + 1,
    container_width,
    container_height
  )
  
  table.insert(M.state.columns, {
    win = win,
    buf = buf,
    dir = dir,
    files = files,
    cursor = 1,
  })
  
  -- Recreate existing columns with new positions
  for i, col in ipairs(M.state.columns) do
    if i < #M.state.columns then
      local new_buf, new_win = create_column_window(
        M.state.container_win,
        i,
        #M.state.columns,
        container_width,
        container_height
      )
      col.buf = new_buf
      col.win = new_win
      setup_column_keymaps(col.buf, i)  -- Add keymaps
      render_files(col.buf, col.files, i == M.state.active_col)
      api.nvim_win_set_cursor(col.win, {col.cursor, 0})
    else
      setup_column_keymaps(col.buf, i)  -- Add keymaps for new column
      render_files(col.buf, col.files, true)
    end
  end
  
  M.state.active_col = #M.state.columns
  update_column_highlights()
  api.nvim_set_current_win(M.state.columns[M.state.active_col].win)
  update_title()
end

setup_column_keymaps = function(buf, col_index)
  local opts = { noremap = true, silent = true, buffer = buf }
  
  vim.keymap.set("n", "j", function() M.move_in_column(1) end, opts)
  vim.keymap.set("n", "k", function() M.move_in_column(-1) end, opts)
  vim.keymap.set("n", "h", function() M.focus_column(-1) end, opts)
  vim.keymap.set("n", "l", function() M.open_or_focus_right() end, opts)
  vim.keymap.set("n", "<CR>", function() M.open_or_focus_right() end, opts)
  vim.keymap.set("n", "q", function() M.close() end, opts)
  vim.keymap.set("n", "<Esc>", function() M.close() end, opts)
  vim.keymap.set("n", ".", function() M.toggle_hidden() end, opts)
  vim.keymap.set("n", "i", function() M.toggle_icons() end, opts)
  vim.keymap.set("n", "?", function() M.show_help() end, opts)
  vim.keymap.set("n", "-", function() M.go_parent() end, opts)
  vim.keymap.set("n", "p", function() M.toggle_preview() end, opts)
  vim.keymap.set("n", "<C-d>", function() M.preview_scroll(10) end, opts)
  vim.keymap.set("n", "<C-u>", function() M.preview_scroll(-10) end, opts)
  vim.keymap.set("n", "|", function() M.toggle_column_separator() end, opts)
end

function M.move_in_column(direction)
  local col = M.state.columns[M.state.active_col]
  if not col or not api.nvim_win_is_valid(col.win) then return end
  
  local current_line = api.nvim_win_get_cursor(col.win)[1]
  local new_line = current_line + direction
  local line_count = api.nvim_buf_line_count(col.buf)
  
  if new_line >= 1 and new_line <= line_count then
    api.nvim_win_set_cursor(col.win, {new_line, 0})
    col.cursor = new_line
    
    -- Update preview if enabled
    if M.state.preview_enabled then
      local file = col.files[new_line]
      if file then
        -- Use the container window as parent for preview
        preview.show(file.path, M.state.container_win, "right")
      end
    end
  end
end

function M.focus_column(direction)
  local new_col = M.state.active_col + direction
  
  -- If trying to go left from the first column, go to parent directory
  if new_col < 1 and M.state.active_col == 1 then
    M.go_parent()
    return
  end
  
  if new_col >= 1 and new_col <= #M.state.columns then
    -- If moving left, remove columns to the right
    if direction < 0 then
      for i = #M.state.columns, new_col + 1, -1 do
        local c = M.state.columns[i]
        if api.nvim_win_is_valid(c.win) then
          api.nvim_win_close(c.win, true)
        end
        table.remove(M.state.columns, i)
      end
      
      -- Recreate all windows with new size
      local container_width = api.nvim_win_get_width(M.state.container_win) - 2
      local container_height = api.nvim_win_get_height(M.state.container_win)
      
      for i, col in ipairs(M.state.columns) do
        if api.nvim_win_is_valid(col.win) then
          api.nvim_win_close(col.win, true)
        end
        
        local buf, win = create_column_window(
          M.state.container_win,
          i,
          #M.state.columns,
          container_width,
          container_height
        )
        
        col.buf = buf
        col.win = win
        setup_column_keymaps(col.buf, i)
        render_files(col.buf, col.files, i == new_col)
        api.nvim_win_set_cursor(col.win, {col.cursor, 0})
      end
    end
    
    M.state.active_col = new_col
    update_column_highlights()
    api.nvim_set_current_win(M.state.columns[M.state.active_col].win)
  end
end

function M.open_or_focus_right()
  local col = M.state.columns[M.state.active_col]
  if not col then return end
  
  local line = col.cursor
  local file = col.files[line]
  if not file then return end
  
  if file.type == "directory" then
    -- Check if next column already shows this directory
    if M.state.columns[M.state.active_col + 1] and 
       M.state.columns[M.state.active_col + 1].dir == file.path then
      M.focus_column(1)
    else
      -- Remove columns to the right
      for i = #M.state.columns, M.state.active_col + 1, -1 do
        local c = M.state.columns[i]
        if api.nvim_win_is_valid(c.win) then
          api.nvim_win_close(c.win, true)
        end
        table.remove(M.state.columns, i)
      end
      
      add_column(file.path)
    end
  else
    M.close()
    vim.cmd("edit " .. fn.fnameescape(file.path))
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
  
  -- Position window with left margin for better layout
  local col = 5  -- 5-character left margin
  
  M.state.container_buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_option(M.state.container_buf, "buftype", "nofile")
  api.nvim_buf_set_option(M.state.container_buf, "modifiable", false)
  
  M.state.container_win = api.nvim_open_win(M.state.container_buf, false, {  -- false to not enter
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
  
  -- Set window highlight to match normal background
  api.nvim_win_set_option(M.state.container_win, "winhighlight", "Normal:Normal,NormalFloat:Normal,FloatBorder:Normal")
  
  M.state.columns = {}
  M.state.active_col = 1
  
  -- Add initial column with current directory
  add_column(fn.getcwd())
  
  -- Setup keymaps for all columns
  for i, col in ipairs(M.state.columns) do
    setup_column_keymaps(col.buf, i)
  end
  
  -- Focus on the first column
  update_column_highlights()
  if M.state.columns[1] and api.nvim_win_is_valid(M.state.columns[1].win) then
    api.nvim_set_current_win(M.state.columns[1].win)
    -- Set buffer as modifiable to allow cursor movement
    vim.cmd('setlocal modifiable')
    vim.cmd('setlocal nomodifiable')
    
    -- Show preview if enabled and files exist
    if M.state.preview_enabled and M.state.columns[1].files and #M.state.columns[1].files > 0 then
      local file = M.state.columns[1].files[1]
      if file then
        preview.show(file.path, M.state.container_win, "right")
      end
    end
  end
end

function M.close()
  -- Close preview window
  preview.close()
  
  for _, col in ipairs(M.state.columns) do
    if api.nvim_win_is_valid(col.win) then
      api.nvim_win_close(col.win, true)
    end
  end
  
  if M.state.container_win and api.nvim_win_is_valid(M.state.container_win) then
    api.nvim_win_close(M.state.container_win, true)
  end
  
  M.state.columns = {}
  M.state.container_win = nil
  M.state.container_buf = nil
  -- Don't reset preview_enabled - keep the config value
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
  
  -- Refresh all columns
  for _, col in ipairs(M.state.columns) do
    col.files = get_files(col.dir)
    render_files(col.buf, col.files, _ == M.state.active_col)
  end
end

function M.toggle_icons()
  M.state.use_icons = not M.state.use_icons
  
  -- Re-render all columns
  for i, col in ipairs(M.state.columns) do
    render_files(col.buf, col.files, i == M.state.active_col)
  end
end

function M.show_help()
  local help_text = {
    "Feather.nvim Split View Help",
    "",
    "Navigation:",
    "  j/k     - Move cursor down/up in column",
    "  h       - Focus left column / Go to parent (at first column)",
    "  l/<CR>  - Open directory in right column / Open file",
    "  -       - Go to parent directory",
    "",
    "Features:",
    "  .       - Toggle hidden files",
    "  i       - Toggle icons",
    "  p       - Toggle file preview",
    "  |       - Toggle column separators",
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
  local col = M.state.columns[M.state.active_col]
  if not col or not api.nvim_win_is_valid(col.win) then return end
  
  M.state.preview_enabled = not M.state.preview_enabled
  
  if M.state.preview_enabled then
    local line = api.nvim_win_get_cursor(col.win)[1]
    local file = col.files[line]
    if file then
      -- Use the container window as parent for preview
      preview.show(file.path, M.state.container_win, "right")
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

function M.toggle_column_separator()
  M.state.column_separator = not M.state.column_separator
  
  -- Recreate all column windows with new border settings
  local container_width = api.nvim_win_get_width(M.state.container_win) - 2
  local container_height = api.nvim_win_get_height(M.state.container_win)
  
  for i, col in ipairs(M.state.columns) do
    -- Close old window
    if api.nvim_win_is_valid(col.win) then
      api.nvim_win_close(col.win, true)
    end
    
    -- Create new window with updated border
    local buf, win = create_column_window(
      M.state.container_win,
      i,
      #M.state.columns,
      container_width,
      container_height
    )
    
    col.buf = buf
    col.win = win
    setup_column_keymaps(col.buf, i)
    render_files(col.buf, col.files, i == M.state.active_col)
    api.nvim_win_set_cursor(col.win, {col.cursor, 0})
  end
  
  update_column_highlights()
  api.nvim_set_current_win(M.state.columns[M.state.active_col].win)
end

function M.go_parent()
  local col = M.state.columns[M.state.active_col]
  if not col then return end
  
  local parent_dir = fn.fnamemodify(col.dir, ":h")
  if parent_dir == col.dir then
    return -- Already at root
  end
  
  -- Remove columns to the right
  for i = #M.state.columns, M.state.active_col, -1 do
    local c = M.state.columns[i]
    if api.nvim_win_is_valid(c.win) then
      api.nvim_win_close(c.win, true)
    end
    table.remove(M.state.columns, i)
  end
  
  -- If we're at the first column, add parent directory to the left
  if M.state.active_col == 1 then
    -- Get parent's parent for context
    local grandparent_dir = fn.fnamemodify(parent_dir, ":h")
    
    -- Insert grandparent column at the beginning if different from parent
    if grandparent_dir ~= parent_dir then
      local files = get_files(grandparent_dir)
      table.insert(M.state.columns, 1, {
        win = nil,
        buf = nil,
        dir = grandparent_dir,
        files = files,
        cursor = 1,
      })
      
      -- Update active column index since we inserted a column at the beginning
      M.state.active_col = 2
      
      -- Find parent directory in grandparent's file list
      local parent_name = fn.fnamemodify(parent_dir, ":t")
      for i, file in ipairs(files) do
        if file.name == parent_name and file.type == "directory" then
          M.state.columns[1].cursor = i
          break
        end
      end
    end
    
    -- Get the current column after potential insertion
    col = M.state.columns[M.state.active_col]
    if not col then
      -- If column doesn't exist, use the first column
      M.state.active_col = 1
      col = M.state.columns[1]
    end
    
    -- Store the original directory name before updating
    local original_dir = col.dir
    
    -- Update current column to show parent directory
    col.dir = parent_dir
    col.files = get_files(parent_dir)
    col.cursor = 1
    
    -- Find current directory in parent's file list
    local current_name = fn.fnamemodify(original_dir, ":t")
    for i, file in ipairs(col.files) do
      if file.name == current_name and file.type == "directory" then
        col.cursor = i
        break
      end
    end
  else
    -- Focus on the parent column
    M.state.active_col = M.state.active_col - 1
  end
  
  -- Recreate all windows
  local container_width = api.nvim_win_get_width(M.state.container_win)
  local container_height = api.nvim_win_get_height(M.state.container_win)
  
  for i, col in ipairs(M.state.columns) do
    if api.nvim_win_is_valid(col.win or 0) then
      api.nvim_win_close(col.win, true)
    end
    
    local buf, win = create_column_window(
      M.state.container_win,
      i,
      #M.state.columns,
      container_width,
      container_height
    )
    
    col.buf = buf
    col.win = win
    setup_column_keymaps(col.buf, i)
    render_files(col.buf, col.files, i == M.state.active_col)
    api.nvim_win_set_cursor(col.win, {col.cursor, 0})
  end
  
  update_column_highlights()
  api.nvim_set_current_win(M.state.columns[M.state.active_col].win)
end

function M.setup(opts)
  if opts.max_columns then
    M.state.max_columns = opts.max_columns
  end
  M.state.show_hidden = opts.show_hidden or false
  M.state.use_icons = opts.use_icons == nil and true or opts.use_icons
  
  -- Get settings from config
  local cfg = config.get()
  M.state.column_separator = cfg.features.column_separator
  M.state.preview_enabled = cfg.preview.enabled
  
  -- Setup highlights if not already done
  local has_highlights = pcall(require, "feather.highlights")
  if has_highlights then
    require("feather.highlights").setup()
  end
end

return M