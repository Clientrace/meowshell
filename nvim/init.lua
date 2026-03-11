-------------------------------------------------------------------------------
-- 1. BOOTSTRAP LAZY.NVIM
-------------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git", "clone", "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-------------------------------------------------------------------------------
-- 2. GLOBAL SETTINGS
-------------------------------------------------------------------------------
vim.g.mapleader = " "
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.termguicolors = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.undofile = true


vim.api.nvim_create_autocmd("FileType", {
    pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
    callback = function()
        vim.bo.shiftwidth = 2
        vim.bo.tabstop = 2
        vim.bo.expandtab = true
    end,
})

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
    pattern = "*",
    callback = function()
        vim.opt.foldmethod = "expr"
        vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
        vim.opt.foldlevel = 99
    end,
})

-------------------------------------------------------------------------------
-- 3. PLUGIN SPECIFICATIONS & CONFIGS
-------------------------------------------------------------------------------
require("lazy").setup({
    -- THEME
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
            require("catppuccin").setup({
                transparent_background = true
            })
            vim.cmd.colorscheme "catppuccin"
        end
    },

    -- LSP + AUTOCOMPLETE
    { 'williamboman/mason.nvim', config = true },
    {
        'williamboman/mason-lspconfig.nvim',
        dependencies = { 'williamboman/mason.nvim' },
        opts = {
            ensure_installed = { 'ts_ls', 'pyright', 'lua_ls' },
        },
    },
    { 'neovim/nvim-lspconfig' },
    { 'hrsh7th/cmp-nvim-lsp' },
    { 'hrsh7th/cmp-buffer' },
    { 'hrsh7th/cmp-path' },
    { 'saadparwaiz1/cmp_luasnip' },
    { 'hrsh7th/nvim-cmp' },
    { 'L3MON4D3/LuaSnip' },

    -- TREESITTER (Syntax Highlighting)
    {
        'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate',
        opts = {
            highlight = {
                enable = true,
            },
            indent = {
                enable = true,
            },
            fold = {
                enable = true,
            },
            ensure_installed = {
                'lua',
                'vim',
                'vimdoc',
                'javascript',
                'typescript',
                'python',
            },
        }
    },

    -- TELESCOPE (Fuzzy Finder)
    {
        'nvim-telescope/telescope.nvim',
        dependencies = { 'nvim-lua/plenary.nvim' },
        config = function()
            local builtin = require('telescope.builtin')

            -- The "Big Three"
            vim.keymap.set('n', '<C-p>', builtin.find_files, { desc = 'Find Files (Cmd+P)' })
            vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find Files' })
            vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Search Text (Grep)' })

            -- The "Context" Pickers
            vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'List Open Buffers' })
            vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Search Help Docs' })
            vim.keymap.set('n', '<leader>fs', builtin.lsp_document_symbols, { desc = 'Find Symbols in File' })

            -- The "Oops, where was I?" Picker
            vim.keymap.set('n', '<leader>fo', builtin.oldfiles, { desc = 'Recently Opened Files' })

            -- Git
            vim.keymap.set('n', '<leader>gs', function() require('neogit').open() end, { desc = 'Git Status (Neogit)' })
        end
    },

    -- GITSIGNS (Git Blame + Gutter Signs)
    {
        'lewis6991/gitsigns.nvim',
        config = function()
            require('gitsigns').setup({
                current_line_blame = true,
                current_line_blame_opts = {
                    delay = 300,
                },
            })
            vim.keymap.set('n', '<leader>gb', '<cmd>Gitsigns blame<CR>', { desc = 'Git Blame (full file)' })
            vim.keymap.set('n', '<leader>gB', '<cmd>Gitsigns toggle_current_line_blame<CR>',
                { desc = 'Toggle Inline Blame' })
            vim.keymap.set('n', '<leader>gp', '<cmd>Gitsigns preview_hunk<CR>', { desc = 'Preview Hunk' })
            vim.keymap.set('n', ']h', '<cmd>Gitsigns next_hunk<CR>', { desc = 'Next Hunk' })
            vim.keymap.set('n', '[h', '<cmd>Gitsigns prev_hunk<CR>', { desc = 'Prev Hunk' })
        end,
    },

    -- NEOGIT (Git Interface)
    {
        'NeogitOrg/neogit',
        dependencies = {
            'nvim-lua/plenary.nvim',
            'sindrets/diffview.nvim',
            'nvim-telescope/telescope.nvim',
        },
        config = true,
    },

    -- CLAUDE CODE (Editor Integration)
    {
        "coder/claudecode.nvim",
        opts = {},
        keys = {
            { "<leader>ac", "<cmd>ClaudeCode<CR>",      desc = "Toggle Claude Terminal" },
            { "<leader>as", "<cmd>ClaudeCodeSend<CR>",  mode = { "n", "v" },            desc = "Send to Claude" },
            { "<leader>ao", "<cmd>ClaudeCodeOpen<CR>",  desc = "Open Claude Terminal" },
            { "<leader>ax", "<cmd>ClaudeCodeClose<CR>", desc = "Close Claude Terminal" },
        },
    },

    -- FORMAT ON SAVE
    {
        'stevearc/conform.nvim',
        event = "BufWritePre",
        opts = {
            formatters_by_ft = {
                python = { "black" },
                typescript = { "prettierd", "prettier", stop_after_first = true },
                typescriptreact = { "prettierd", "prettier", stop_after_first = true },
                javascript = { "prettierd", "prettier", stop_after_first = true },
                javascriptreact = { "prettierd", "prettier", stop_after_first = true },
            },
            format_on_save = {
                timeout_ms = 3000,
                lsp_format = "fallback",
            },
        },
    },

    -- STATUS LINE
    {
        'nvim-lualine/lualine.nvim',
        config = function()
            require('lualine').setup()
        end
    },
})

-------------------------------------------------------------------------------
-- 4. LSP FUNCTIONALITY (Wiring it up)
-------------------------------------------------------------------------------
vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(event)
        local opts = { buffer = event.buf, remap = false }
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
    end,
})

local capabilities = require('cmp_nvim_lsp').default_capabilities()

vim.lsp.config('*', {
    capabilities = capabilities,
})

vim.lsp.enable({ 'ts_ls', 'pyright', 'lua_ls' })

-- Re-trigger FileType for already-opened buffers so LSP attaches
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
        vim.api.nvim_exec_autocmds('FileType', { buffer = buf })
    end
end

-- Autocomplete (VSCode-like)
local cmp = require('cmp')
local luasnip = require('luasnip')

cmp.setup({
    snippet = {
        expand = function(args)
            luasnip.lsp_expand(args.body)
        end,
    },
    sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
    }, {
        { name = 'buffer' },
        { name = 'path' },
    }),
    mapping = cmp.mapping.preset.insert({
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
            else
                fallback()
            end
        end, { 'i', 's' }),
        ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
            else
                fallback()
            end
        end, { 'i', 's' }),
    }),
    window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
    },
})

-------------------------------------------------------------------------------
-- 5. EXTRA KEYBINDS
-------------------------------------------------------------------------------
-- Netrw (Standard Vim File Explorer)
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- Copy relative path
vim.keymap.set("n", "<leader>cf", '<cmd>let @+ = expand("%")<CR>', { desc = "Copy Relative Path" })

-- Copy absolute path
vim.keymap.set("n", "<leader>cF", '<cmd>let @+ = expand("%:p")<CR>', { desc = "Copy Absolute Path" })

