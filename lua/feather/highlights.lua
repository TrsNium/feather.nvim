local M = {}

-- Define highlight groups
M.highlights = {
  FeatherDirectory = {
    fg = "#7aa2f7",  -- Blue
    bold = true,
  },
  FeatherFile = {
    fg = "#c0caf5",  -- Light gray
  },
  FeatherExecutable = {
    fg = "#9ece6a",  -- Green
    bold = true,
  },
  FeatherSymlink = {
    fg = "#bb9af7",  -- Purple
    italic = true,
  },
  FeatherSpecial = {
    fg = "#e0af68",  -- Yellow
  },
  FeatherHidden = {
    fg = "#565f89",  -- Dim gray
    italic = true,
  },
  FeatherIcon = {
    fg = "#7dcfff",  -- Cyan
  },
  FeatherCurrent = {
    bg = "#292e42",  -- Dark blue background
    bold = true,
  },
}

-- Setup highlight groups
function M.setup()
  for group, opts in pairs(M.highlights) do
    vim.api.nvim_set_hl(0, group, opts)
  end
  
  -- Link to existing highlight groups for better theme compatibility
  vim.api.nvim_set_hl(0, "FeatherDirectory", { link = "Directory" })
  vim.api.nvim_set_hl(0, "FeatherFile", { link = "Normal" })
  vim.api.nvim_set_hl(0, "FeatherExecutable", { link = "String" })
  vim.api.nvim_set_hl(0, "FeatherSymlink", { link = "Special" })
  vim.api.nvim_set_hl(0, "FeatherSpecial", { link = "Type" })
  vim.api.nvim_set_hl(0, "FeatherHidden", { link = "Comment" })
  vim.api.nvim_set_hl(0, "FeatherIcon", { link = "Function" })
  vim.api.nvim_set_hl(0, "FeatherCurrent", { link = "CursorLine" })
  
  -- Fix floating window background to match the normal background
  vim.api.nvim_set_hl(0, "NormalFloat", { link = "Normal" })
  vim.api.nvim_set_hl(0, "FloatBorder", { link = "Normal" })
end

-- Get highlight group for file type
function M.get_highlight(file_type, file_name)
  -- Hidden files
  if file_name and file_name:match("^%.") then
    return "FeatherHidden"
  end
  
  -- By type
  if file_type == "directory" then
    return "FeatherDirectory"
  elseif file_type == "link" then
    return "FeatherSymlink"
  elseif file_type == "executable" then
    return "FeatherExecutable"
  elseif file_type == "special" then
    return "FeatherSpecial"
  else
    return "FeatherFile"
  end
end

return M