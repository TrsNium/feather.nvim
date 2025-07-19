# feather.nvim

A modern, lightweight file explorer for Neovim with dual-pane layout and file preview support, inspired by [rnvimr](https://github.com/kevinhwang91/rnvimr) and [NERDTree](https://github.com/preservim/nerdtree).

## ✨ Features

- 📁 **Dual-pane layout** - Browse files and directories with side-by-side layout
- 👁️ **Real-time preview** - Preview files instantly without opening them
- 🔍 **Advanced search** - Quick file search with navigation (/, n, N)
- 🎨 **Rich icon support** - Beautiful file type icons with customizable folder icons
- 🔲 **Split view mode** - Multi-column directory browsing (Miller columns)
- 👻 **Hidden files toggle** - Show/hide dotfiles with one key
- ⚡ **Fast and lightweight** - Optimized for performance
- 🎹 **Intuitive navigation** - Vim-like key mappings
- 🎨 **Customizable borders** - Rounded, single, double border styles
- 📁 **Current directory** - Open in current file's directory
- 🔄 **Auto-sync** - Preview updates automatically with cursor movement

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
- `:FeatherCurrent` - Open the file explorer in current file's directory

### Default Key Mappings

#### Normal Mode (Floating Window)
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
| `n`/`N` | Next/Previous search result |
| `?` | Show help |
| `<C-d>` | Scroll preview down |
| `<C-u>` | Scroll preview up |
| `q`/`<Esc>` | Close Feather |

#### Split View Mode (Default)
| Key | Action |
|-----|--------|
| `j`/`k` | Navigate down/up in current column |
| `h` | Focus left column / Go to parent (at first column) |
| `l`/`<CR>` | Open directory in new column / Open file |
| `-` | Go to parent directory |
| `.` | Toggle hidden files |
| `i` | Toggle icons |
| `p` | Toggle file preview |
| `/` | Search files in current column |
| `n`/`N` | Next/Previous search result |
| `|` | Toggle column separators |
| `?` | Show help |
| `<C-d>` | Scroll preview down |
| `<C-u>` | Scroll preview up |
| `q`/`<Esc>` | Close Feather |

## Configuration

### Default Configuration

```lua
require("feather").setup({
  window = {
    width = 0.42,        -- 42% width for optimal center split
    height = 0.8,        -- 80% of screen height
    border = "rounded",  -- Border style: "rounded", "single", "double", etc.
    position = "center",
  },
  icons = {
    enabled = true,
    folder = "",       -- Custom folder icon
    default_file = "",
  },
  features = {
    show_hidden = false,
    auto_close = true,
    split_view = true,       -- Enable split view mode (default)
    max_columns = 4,         -- Maximum columns in split view
    column_separator = false, -- Show vertical separator between columns
  },
  preview = {
    enabled = true,          -- Enable preview by default
    position = "auto",       -- "auto", "right", "bottom"
    border = "single",       -- Border style for preview window
    max_lines = 100,         -- Maximum lines to show in preview
    min_width = 30,          -- Minimum width for preview window
    min_height = 5,          -- Minimum height for preview window
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

### Example Configuration with Custom Settings

```lua
-- Example setup with custom folder icon and keymaps
require("feather").setup({
  window = {
    width = 0.42,
    height = 0.8,
    border = "rounded",
  },
  icons = {
    enabled = true,
    folder = "",  -- Custom folder icon
    default_file = "",
  },
  features = {
    show_hidden = true,      -- Show hidden files by default
    split_view = true,       -- Use split view mode
    max_columns = 4,
    column_separator = false,
  },
  preview = {
    enabled = true,
    border = "rounded",      -- Match main window border
    max_lines = 100,
  },
})

-- Example keymaps
vim.keymap.set("n", "<leader>e", "<cmd>Feather<cr>", { desc = "Toggle Feather" })
vim.keymap.set("n", "<leader>fe", "<cmd>FeatherCurrent<cr>", { desc = "Feather in current dir" })
```

## Requirements

- Neovim 0.7.0 or higher
- A [Nerd Font](https://www.nerdfonts.com/) for icon support (recommended)

## Screenshots

### Split View Mode with Preview
```
[File Tree] | [Preview]
```

- Dual-pane layout with file tree on the left and preview on the right
- Real-time preview updates as you navigate
- Customizable borders and margins

### Multi-column Directory Browsing
```
[Parent] | [Current] | [Child] | [Preview]
```

- Miller column style navigation
- Up to 4 columns for deep directory exploration
- Smooth column transitions

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT
