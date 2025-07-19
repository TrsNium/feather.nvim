local M = {}
local api = vim.api
local fn = vim.fn

M.state = {
  win = nil,
  buf = nil,
  current_file = nil,
  max_lines = 100,
}

local binary_extensions = {
  "png", "jpg", "jpeg", "gif", "bmp", "ico", "svg",
  "mp3", "mp4", "avi", "mov", "mkv", "flv",
  "zip", "tar", "gz", "rar", "7z",
  "exe", "dll", "so", "dylib",
  "pdf", "doc", "docx", "xls", "xlsx",
}

local function is_binary(filepath)
  local ext = fn.fnamemodify(filepath, ":e"):lower()
  for _, binary_ext in ipairs(binary_extensions) do
    if ext == binary_ext then
      return true
    end
  end
  
  -- Check if file contains null bytes
  local file = io.open(filepath, "rb")
  if file then
    local chunk = file:read(8192) or ""
    file:close()
    return chunk:find("\0") ~= nil
  end
  
  return false
end

local function get_file_info(filepath)
  local stat = vim.loop.fs_stat(filepath)
  if not stat then
    return "Cannot read file"
  end
  
  local size = stat.size
  local size_str
  if size < 1024 then
    size_str = size .. " B"
  elseif size < 1024 * 1024 then
    size_str = string.format("%.1f KB", size / 1024)
  elseif size < 1024 * 1024 * 1024 then
    size_str = string.format("%.1f MB", size / (1024 * 1024))
  else
    size_str = string.format("%.1f GB", size / (1024 * 1024 * 1024))
  end
  
  local mod_time = os.date("%Y-%m-%d %H:%M:%S", stat.mtime.sec)
  local permissions = string.format("%o", stat.mode % 512)
  
  return {
    size = size_str,
    modified = mod_time,
    permissions = permissions,
    type = stat.type,
  }
end

local function render_binary_preview(buf, filepath)
  local info = get_file_info(filepath)
  local ext = fn.fnamemodify(filepath, ":e"):lower()
  local name = fn.fnamemodify(filepath, ":t")
  
  local lines = {
    "Binary File Preview",
    "",
    "Name: " .. name,
    "Type: " .. ext:upper() .. " file",
    "Size: " .. info.size,
    "Modified: " .. info.modified,
    "Permissions: " .. info.permissions,
    "",
    "This is a binary file and cannot be previewed as text.",
  }
  
  -- Add specific info for known types
  if vim.tbl_contains({"png", "jpg", "jpeg", "gif", "bmp", "ico", "svg"}, ext) then
    table.insert(lines, "")
    table.insert(lines, "Image file - use an image viewer to open.")
  elseif vim.tbl_contains({"mp3", "mp4", "avi", "mov", "mkv", "flv"}, ext) then
    table.insert(lines, "")
    table.insert(lines, "Media file - use a media player to open.")
  elseif vim.tbl_contains({"zip", "tar", "gz", "rar", "7z"}, ext) then
    table.insert(lines, "")
    table.insert(lines, "Archive file - use an archive manager to open.")
  end
  
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

local function render_text_preview(buf, filepath)
  local lines = {}
  local file = io.open(filepath, "r")
  
  if not file then
    lines = {"Error: Cannot read file"}
  else
    local line_count = 0
    for line in file:lines() do
      line_count = line_count + 1
      if line_count > M.state.max_lines then
        table.insert(lines, "... (" .. line_count .. " more lines)")
        break
      end
      table.insert(lines, line)
    end
    file:close()
    
    if line_count == 0 then
      lines = {"(Empty file)"}
    end
  end
  
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Try to detect and set appropriate filetype
  local ft = vim.filetype.match({ filename = filepath })
  if ft then
    api.nvim_buf_set_option(buf, "filetype", ft)
  end
end

local function render_directory_preview(buf, dirpath)
  local files = {}
  local dirs = {}
  local handle = vim.loop.fs_scandir(dirpath)
  
  if handle then
    while true do
      local name, type = vim.loop.fs_scandir_next(handle)
      if not name then break end
      if type == "directory" then
        table.insert(dirs, name .. "/")
      else
        table.insert(files, name)
      end
    end
  end
  
  table.sort(dirs)
  table.sort(files)
  
  local lines = {
    "Directory Preview",
    "",
    "Contents: " .. #dirs .. " directories, " .. #files .. " files",
    "",
  }
  
  -- Add directories first
  for _, dir in ipairs(dirs) do
    table.insert(lines, "  📁 " .. dir)
  end
  
  -- Add files
  for _, file in ipairs(files) do
    table.insert(lines, "  📄 " .. file)
  end
  
  if #lines == 4 then
    table.insert(lines, "(Empty directory)")
  end
  
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

function M.render_preview(buf, filepath)
  local stat = vim.loop.fs_stat(filepath)
  if not stat then
    api.nvim_buf_set_lines(buf, 0, -1, false, {"Cannot read file: " .. filepath})
    return
  end
  
  if stat.type == "directory" then
    render_directory_preview(buf, filepath)
  elseif is_binary(filepath) then
    render_binary_preview(buf, filepath)
  else
    render_text_preview(buf, filepath)
  end
  
  api.nvim_buf_set_option(buf, "modifiable", false)
end

function M.show(filepath, parent_win, position)
  -- Close existing preview if any
  M.close()
  
  if not filepath or filepath == "" then
    vim.notify("Preview: No filepath provided", vim.log.levels.WARN)
    return
  end
  
  -- Validate parent window
  if not parent_win or not api.nvim_win_is_valid(parent_win) then
    vim.notify("Preview: Invalid parent window", vim.log.levels.ERROR)
    return
  end
  
  -- Debug info
  -- vim.notify("Preview: Showing " .. filepath .. " next to window " .. parent_win, vim.log.levels.INFO)
  
  -- Create preview buffer
  M.state.buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_option(M.state.buf, "buftype", "nofile")
  api.nvim_buf_set_option(M.state.buf, "bufhidden", "wipe")
  api.nvim_buf_set_option(M.state.buf, "modifiable", true)
  
  -- Calculate window position
  local win_config = api.nvim_win_get_config(parent_win)
  local parent_width = win_config.width or api.nvim_win_get_width(parent_win)
  local parent_height = win_config.height or api.nvim_win_get_height(parent_win)
  
  -- Get parent window position
  local parent_row, parent_col
  if win_config.relative == "win" then
    -- For nested windows (like split view columns), calculate absolute position
    local parent_parent_win = win_config.win
    local parent_parent_config = api.nvim_win_get_config(parent_parent_win)
    parent_row = (parent_parent_config.row or 0) + (win_config.row or 0)
    parent_col = (parent_parent_config.col or 0) + (win_config.col or 0)
  else
    parent_row = win_config.row or 0
    parent_col = win_config.col or 0
  end
  
  -- Get actual screen dimensions
  local screen_width = vim.o.columns
  local screen_height = vim.o.lines
  
  -- Calculate available space
  local space_right = screen_width - (parent_col + parent_width)
  local space_bottom = screen_height - (parent_row + parent_height)
  
  local width, height, row, col
  
  -- Determine best position based on available space
  if position == "auto" or not position then
    -- If parent window is narrow or not enough space on right, use bottom
    if parent_width < 60 or space_right < 40 then
      position = "bottom"
    else
      position = "right"
    end
  end
  
  if position == "right" then
    width = math.min(math.floor(parent_width * 0.5), space_right - 2)
    height = parent_height - 2
    row = 1
    col = parent_width + 1
    
    -- If preview would be too narrow, switch to bottom
    if width < 30 then
      position = "bottom"
    end
  end
  
  if position == "bottom" then
    width = parent_width
    height = math.min(math.floor(parent_height * 0.4), space_bottom - 2, 15)
    row = parent_height + 1
    col = 0
    
    -- If not enough space at bottom, don't show preview
    if height < 5 then
      return
    end
  end
  
  -- Create preview window
  M.state.win = api.nvim_open_win(M.state.buf, false, {
    relative = "win",
    win = parent_win,
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "single",
    title = " Preview ",
    title_pos = "center",
  })
  
  -- Set window highlight to match normal background
  api.nvim_win_set_option(M.state.win, "winhighlight", "Normal:Normal,NormalFloat:Normal,FloatBorder:Normal")
  
  -- Set window options
  api.nvim_win_set_option(M.state.win, "cursorline", false)
  api.nvim_win_set_option(M.state.win, "number", true)
  api.nvim_win_set_option(M.state.win, "relativenumber", false)
  api.nvim_win_set_option(M.state.win, "wrap", true)
  api.nvim_win_set_option(M.state.win, "winhl", "Normal:Normal,FloatBorder:FloatBorder")
  
  -- Render content based on file type
  local stat = vim.loop.fs_stat(filepath)
  if stat then
    if stat.type == "directory" then
      render_directory_preview(M.state.buf, filepath)
    elseif is_binary(filepath) then
      render_binary_preview(M.state.buf, filepath)
    else
      render_text_preview(M.state.buf, filepath)
    end
  else
    api.nvim_buf_set_lines(M.state.buf, 0, -1, false, {"Error: File not found"})
  end
  
  api.nvim_buf_set_option(M.state.buf, "modifiable", false)
  M.state.current_file = filepath
end

function M.close()
  if M.state.win and api.nvim_win_is_valid(M.state.win) then
    api.nvim_win_close(M.state.win, true)
  end
  M.state.win = nil
  M.state.buf = nil
  M.state.current_file = nil
end

function M.update(filepath, parent_win)
  if filepath ~= M.state.current_file then
    M.show(filepath, parent_win, "auto")
  end
end

function M.toggle(filepath, parent_win)
  if M.state.win and api.nvim_win_is_valid(M.state.win) then
    M.close()
  else
    M.show(filepath, parent_win, "auto")
  end
end

function M.scroll(direction)
  if M.state.win and api.nvim_win_is_valid(M.state.win) then
    local current_win = api.nvim_get_current_win()
    api.nvim_set_current_win(M.state.win)
    
    if direction > 0 then
      vim.cmd("normal! " .. direction .. "j")
    else
      vim.cmd("normal! " .. math.abs(direction) .. "k")
    end
    
    api.nvim_set_current_win(current_win)
  end
end

return M