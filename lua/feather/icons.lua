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
  lock = "",  -- For lock files
  env = "",   -- For .env files
}

-- Additional dot file mappings
M.dotfile_icons = {
  [".gitignore"] = "",
  [".gitattributes"] = "",
  [".gitmodules"] = "",
  [".dockerignore"] = "󰡨",
  [".env"] = "",
  [".env.local"] = "",
  [".env.development"] = "",
  [".env.production"] = "",
  [".editorconfig"] = "",
  [".eslintrc"] = "",
  [".eslintrc.js"] = "",
  [".eslintrc.json"] = "",
  [".prettierrc"] = "",
  [".prettierrc.js"] = "",
  [".prettierrc.json"] = "",
  [".babelrc"] = "",
  [".npmrc"] = "",
  [".yarnrc"] = "",
  [".nvmrc"] = "",
  ["package-lock.json"] = "",
  ["yarn.lock"] = "",
  ["Gemfile.lock"] = "",
  ["Cargo.lock"] = "",
}

-- Folder icon options:
--   "" -- Solid folder
--   "" -- Open folder  
--   "󰉋" -- Folder with line
--   "" -- Outlined folder
--   "" -- Simple folder
M.folder_icon = ""  -- Using solid folder icon
M.folder_open_icon = ""  -- Open folder icon
M.default_file_icon = "󰈙"

function M.get_icon(filename, is_dir)
  if is_dir then
    return M.folder_icon
  end
  
  -- Check dotfile_icons table first for exact matches
  if M.dotfile_icons[filename] then
    return M.dotfile_icons[filename]
  end
  
  -- Check for special files
  local lower_name = filename:lower()
  if lower_name == "dockerfile" then
    return M.file_icons.dockerfile
  elseif lower_name == "makefile" then
    return M.file_icons.makefile
  elseif lower_name:match("^%.git") then
    -- Any file starting with .git
    return M.file_icons.git or ""
  elseif lower_name:match("^%.") then
    -- Generic dot file icon for other dot files
    return ""
  end
  
  -- Check by extension
  local ext = filename:match("^.+%.(.+)$")
  if ext then
    return M.file_icons[ext:lower()] or M.default_file_icon
  end
  
  return M.default_file_icon
end

return M