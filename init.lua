-- =========================
-- Basic Options
-- =========================
-- Set leader key first
vim.g.mapleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.smartindent = true
vim.opt.autoindent = true
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.cursorline = true
vim.opt.showmatch = true
vim.opt.mouse = "a"
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- =========================
-- Lazy.nvim bootstrap
-- =========================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- =========================
-- Plugins
-- =========================
require("lazy").setup({
  -- Mason for managing LSP servers, formatters, and linters
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup({
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗"
          }
        }
      })
    end
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "pyright",      -- Python LSP
          "lua_ls",       -- Lua LSP
          "tinymist",     -- Typst LSP
        },
        automatic_installation = true,
      })
    end
  },

  -- Bracket auto-closing
  { "windwp/nvim-autopairs", config = true },

  -- Syntax highlighting & indentation
  {
      "nvim-treesitter/nvim-treesitter",
      build = ":TSUpdate",
      dependencies = {
          "nvim-treesitter/nvim-treesitter-textobjects"
      },
      config = function()
          require("nvim-treesitter.configs").setup({
              highlight = { 
                enable = true,
                additional_vim_regex_highlighting = false,
              },
              indent = { enable = true },
              ensure_installed = {
                  "bash",
                  "c",
                  "lua",
                  "vim",
                  "javascript",
                  "html",
                  "css",
                  "python",
                  "rust",
                  "typst"  -- Add Typst syntax highlighting
              },
              auto_install = true,
              textobjects = { 
                select = {
                  enable = true,
                  lookahead = true,
                },
              },
          })
      end
  },

  -- Autocomplete & LSP
  { "neovim/nvim-lspconfig" },
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-buffer" },
  { "L3MON4D3/LuaSnip" },
  { "saadparwaiz1/cmp_luasnip" },

  -- Colorscheme
  { "folke/tokyonight.nvim",
    config = function()
      vim.cmd([[colorscheme tokyonight]])
    end
  },

  -- File explorer
  { "nvim-tree/nvim-tree.lua", 
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
      
      require("nvim-tree").setup()
      vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { noremap = true, silent = true })
    end
  },

  -- Typst support with live preview
  {
    "kaarmu/typst.vim",
    ft = "typst",
  },
  {
    "chomosuke/typst-preview.nvim",
    ft = "typst",
    version = "0.3.*",
    build = function() require("typst-preview").update() end,
    config = function()
      require("typst-preview").setup({
        -- Use Windows start command for better compatibility
        open_cmd = "start %s", -- Will open with default browser
        -- Alternative: open_cmd = "firefox %s",
        -- invert_colors = "never", -- or "auto" or "always"
      })
    end,
  },

})

-- =========================
-- LSP Example (Python)
-- =========================
-- Configure diagnostics appearance
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

-- Define diagnostic signs
local signs = { Error = "󰅚 ", Warn = "󰀪 ", Hint = "󰌶 ", Info = " " }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

-- Configure Typst LSP
local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- Add Typst LSP configuration with tinymist
vim.lsp.config.tinymist = {
  cmd = { "tinymist" },
  filetypes = { "typst" },
  root_markers = { ".git", "main.typ" },
  capabilities = capabilities,
  settings = {
    exportPdf = "onType", -- Export PDF on every change
    serverPath = "" -- Leave empty to use tinymist from PATH
  }
}

vim.lsp.enable("tinymist")

vim.lsp.config.pyright = {
  cmd = { "pyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", "pyrightconfig.json", ".git" },
  capabilities = capabilities,
}

vim.lsp.enable("pyright")

-- LSP Keymaps for tooltips and navigation
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    local opts = { buffer = ev.buf }
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts) -- Show tooltip on hover
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
    vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
    vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
    vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts) -- Show diagnostic tooltip
    
    -- Typst-specific keymaps
    if vim.bo[ev.buf].filetype == "typst" then
      vim.keymap.set("n", "<leader>tp", ":TypstPreviewToggle<CR>", 
        { buffer = ev.buf, desc = "Toggle Typst preview", silent = true })
    end
  end,
})

-- =========================
-- Autocomplete setup
-- =========================
local cmp = require("cmp")
cmp.setup({
  snippet = {
    expand = function(args)
      require("luasnip").lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif require("luasnip").expand_or_jumpable() then
        require("luasnip").expand_or_jump()
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif require("luasnip").jumpable(-1) then
        require("luasnip").jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip" },
    { name = "buffer" },
  }),
})
