local M = {}

M.file_icons = {
  lua = "",
  vim = "",
  py = "",
  js = "",
  ts = "󰛦",
  jsx = "󰜈",
  tsx = "󰜈",
  json = "󰘦",
  md = "󰍔",
  txt = "󰈙",
  rs = "",
  go = "󰟓",
  c = "",
  cpp = "",
  h = "",
  hpp = "",
  java = "",
  rb = "",
  php = "󰌟",
  html = "",
  css = "",
  scss = "",
  yaml = "",
  yml = "",
  toml = "",
  ini = "",
  conf = "",
  sh = "",
  bash = "",
  zsh = "",
  fish = "",
  git = "",
  gitignore = "",
  dockerfile = "󰡨",
  makefile = "",
}

M.folder_icon = ""
M.default_file_icon = "󰈙"

function M.get_icon(filename, is_dir)
  if is_dir then
    return M.folder_icon
  end
  
  local ext = filename:match("^.+%.(.+)$")
  if ext then
    return M.file_icons[ext:lower()] or M.default_file_icon
  end
  
  local lower_name = filename:lower()
  if lower_name == "dockerfile" then
    return M.file_icons.dockerfile
  elseif lower_name == "makefile" then
    return M.file_icons.makefile
  elseif lower_name == ".gitignore" then
    return M.file_icons.gitignore
  end
  
  return M.default_file_icon
end

return M