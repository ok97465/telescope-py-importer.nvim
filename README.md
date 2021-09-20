# telescope-py-importer.nvim

![DEMO](/doc/demo.gif)

## Overview

This telescope displays callable names in workspace. After searching a callable name you
want, if you press \<enter\>, it inserts a import statement to top of buffer. If you press
\<tab\>, it inserts a import statement to top of buffer, and type the callable name at
cursor position.

- It doesn't use treesitter, lsp.
- It need ripgrep, telescope.nvim, vim-isort.
- It supports only class, function.

## Installation

```vim
Plug 'fisadev/vim-isort'
Plug 'nvim-telescope/telescope.nvim'
Plug 'ok97465/telescope-py-importer.nvim'
```

## Configuration

```lua
require('telescope').load_extension('py_importer')
```

## Usage

```lua
require 'telescope'.extensions.py_importer.workspace({layout_config={prompt_position="top"}, sorting_strategy="ascending"})
```

