-- Test script to verify feather configuration
-- Run this with :luafile %

-- Clear cache
package.loaded['feather'] = nil
package.loaded['feather.config'] = nil
package.loaded['feather.split_view'] = nil

-- Load and setup
local feather = require('feather')

print("Before setup:")
local config = require('feather.config')
print("Config options empty?", vim.tbl_isempty(config.options))

-- Setup with split_view enabled
feather.setup({
  features = {
    split_view = true,
    show_hidden = true,
  }
})

print("\nAfter setup:")
local cfg = config.get()
print("Split view enabled:", cfg.features.split_view)
print("Show hidden:", cfg.features.show_hidden)

-- Test opening
print("\nOpening feather...")
feather.open()