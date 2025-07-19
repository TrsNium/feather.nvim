# feather.nvim

A lightweight file explorer for Neovim with floating window support, inspired by [rnvimr](https://github.com/kevinhwang91/rnvimr) and [NERDTree](https://github.com/preservim/nerdtree).

## Features

- 📁 Browse files and directories in a floating window
- 🎨 Icon support for file types
- 🔍 Quick file search
- 👻 Toggle hidden files visibility
- ⚡ Fast and lightweight
- 🎹 Intuitive key mappings
- 🔲 Split view mode - see multiple directories at once
- 👁️ File preview - preview files without opening them

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "TrsNium/feather.nvim",
  config = function()
    require("feather").setup({
      -- your configuration
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "TrsNium/feather.nvim",
  config = function()
    require("feather").setup({
      -- your configuration
    })
  end
}
```

## Usage

### Commands

- `:Feather` - Toggle the file explorer
- `:FeatherOpen` - Open the file explorer
- `:FeatherClose` - Close the file explorer

### Default Key Mappings

#### Normal Mode
| Key | Action |
|-----|--------|
| `j`/`k` | Navigate down/up |
| `h` | Go to parent directory |
| `l`/`<CR>` | Open file/directory |
| `~` | Go to home directory |
| `.` | Toggle hidden files |
| `i` | Toggle icons |
| `p` | Toggle file preview |
| `/` | Search files |
| `?` | Show help |
| `<C-d>` | Scroll preview down |
| `<C-u>` | Scroll preview up |
| `q`/`<Esc>` | Close Feather |

#### Split View Mode
| Key | Action |
|-----|--------|
| `j`/`k` | Navigate down/up in current column |
| `h` | Focus left column |
| `l`/`<CR>` | Open directory in new column / Open file |
| `.` | Toggle hidden files |
| `i` | Toggle icons |
| `?` | Show help |
| `q`/`<Esc>` | Close Feather |

## Configuration

```lua
require("feather").setup({
  window = {
    width = 0.8,  -- 80% of screen width
    height = 0.8, -- 80% of screen height
    border = "rounded",
    position = "center",
  },
  icons = {
    enabled = true,
    folder = "",
    default_file = "",
  },
  features = {
    show_hidden = false,
    auto_close = true,
    split_view = false,  -- Enable split view mode
    max_columns = 4,     -- Maximum columns in split view
  },
  preview = {
    enabled = false,      -- Enable preview by default
    position = "auto",    -- "auto", "right", "bottom"
    max_lines = 100,      -- Maximum lines to show in preview
    min_width = 30,       -- Minimum width for preview window
    min_height = 5,       -- Minimum height for preview window
  },
  keymaps = {
    quit = { "q", "<Esc>" },
    open = { "<CR>", "l" },
    parent = { "h" },
    down = { "j" },
    up = { "k" },
    toggle_hidden = { "." },
    toggle_icons = { "i" },
    toggle_preview = { "p" },
    preview_scroll_down = { "<C-d>" },
    preview_scroll_up = { "<C-u>" },
    home = { "~" },
    search = { "/" },
    help = { "?" },
  },
})
```

## Requirements

- Neovim 0.7.0 or higher
- A [Nerd Font](https://www.nerdfonts.com/) for icon support (optional)

## License

MIT