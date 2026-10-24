vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.number = true
vim.opt.mouse = "a"

-- markdown
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.conceallevel = 2
vim.opt.concealcursor = ""

-- modern editor
vim.opt.termguicolors = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.updatetime = 250

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
    vim.opt_local.conceallevel = 2
  end,
})

-- transparent background
local function set_transparent()
  local groups = {
    "Normal",
    "NormalNC",
    "NormalFloat",
    "FloatBorder",
    "SignColumn",
    "EndOfBuffer",
    "LineNr",
    "CursorLineNr",
    "StatusLine",
    "StatusLineNC",

    -- popup / completion / diagnostics
    "Pmenu",
    "PmenuSel",
    "DiagnosticVirtualTextError",
    "DiagnosticVirtualTextWarn",
    "DiagnosticVirtualTextInfo",
    "DiagnosticVirtualTextHint",

    -- markdown / render-markdown
    "RenderMarkdownCode",
    "RenderMarkdownCodeInline",
    "RenderMarkdownQuote",
  }

  for _, group in ipairs(groups) do
    vim.api.nvim_set_hl(0, group, { bg = "none" })
  end
end

set_transparent()

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = set_transparent,
})
