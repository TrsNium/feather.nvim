local M = {}

function M.check_config()
  local config = require("feather.config").get()
  print("=== Feather.nvim Config Debug ===")
  print("Split view enabled: " .. tostring(config.features.split_view))
  print("Icons enabled: " .. tostring(config.icons.enabled))
  print("Show hidden: " .. tostring(config.features.show_hidden))
  print("Max columns: " .. tostring(config.features.max_columns))
  
  -- Also check if setup was called
  local feather = require('feather')
  print("User setup done: " .. tostring(feather._user_setup_done or false))
  
  print("\nFull config:")
  print(vim.inspect(config))
end

function M.force_reload_and_setup()
  -- Clear all cached modules
  package.loaded['feather'] = nil
  package.loaded['feather.config'] = nil
  package.loaded['feather.split_view'] = nil
  package.loaded['feather.preview'] = nil
  package.loaded['feather.icons'] = nil
  package.loaded['feather.highlights'] = nil
  
  -- Reload and setup with user config
  local feather = require('feather')
  local user_config = {
    features = {
      split_view = true,
      show_hidden = true,
      auto_close = true,
      max_columns = 4,
    },
    -- Copy other settings from init.lua
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
  }
  
  feather.setup(user_config)
  print("Feather reloaded with split_view = true")
  
  -- Check config after reload
  M.check_config()
end

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