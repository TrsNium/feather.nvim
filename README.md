# feather.nvim

A lightweight file explorer for Neovim with floating window support, inspired by [rnvimr](https://github.com/kevinhwang91/rnvimr) and [NERDTree](https://github.com/preservim/nerdtree).

## Features

- 📁 Browse files and directories in a floating window
- 🎨 Icon support for file types
- 🔍 Quick file search
- 👻 Toggle hidden files visibility
- ⚡ Fast and lightweight
- 🎹 Intuitive key mappings

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

| Key | Action |
|-----|--------|
| `j`/`k` | Navigate down/up |
| `h` | Go to parent directory |
| `l`/`<CR>` | Open file/directory |
| `~` | Go to home directory |
| `.` | Toggle hidden files |
| `i` | Toggle icons |
| `/` | Search files |
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
  },
  keymaps = {
    quit = { "q", "<Esc>" },
    open = { "<CR>", "l" },
    parent = { "h" },
    down = { "j" },
    up = { "k" },
    toggle_hidden = { "." },
    toggle_icons = { "i" },
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