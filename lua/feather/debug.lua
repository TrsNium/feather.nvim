local M = {}

function M.check_icon_support()
  local icons = require("feather.icons")
  local test_icon = icons.folder_icon
  
  print("=== Feather.nvim Icon Debug ===")
  print("Folder icon: '" .. test_icon .. "'")
  print("Icon byte length: " .. #test_icon)
  print("Icon codepoint: " .. vim.fn.char2nr(test_icon))
  
  -- Check if icons are enabled
  local config = require("feather.config").get()
  print("Icons enabled: " .. tostring(config.icons.enabled))
  
  -- Test rendering
  print("\nTest icons:")
  print("Folder: " .. icons.folder_icon)
  print("Lua file: " .. icons.file_icons.lua)
  print("Default file: " .. icons.default_file_icon)
  
  -- Check font
  print("\nCurrent font: " .. vim.o.guifont)
  
  return true
end

function M.test_render()
  local icons = require("feather.icons")
  local test_files = {
    { name = "test_folder", type = "directory" },
    { name = "test.lua", type = "file" },
    { name = "test.py", type = "file" },
    { name = "unknown.xyz", type = "file" },
  }
  
  print("\n=== Icon Rendering Test ===")
  for _, file in ipairs(test_files) do
    local icon = icons.get_icon(file.name, file.type == "directory")
    print(string.format("%s %s (icon: '%s')", icon, file.name, icon))
  end
end

return M