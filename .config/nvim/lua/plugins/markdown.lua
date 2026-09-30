return {
  {
    "nvim-treesitter/nvim-treesitter",

    branch = "master",

    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },

    opts = {
      ensure_installed = {
        "markdown",
        "markdown_inline",
        "lua",
        "vim",
        "vimdoc",
        "query",
        "c",
        "cpp",
        "cmake",
        "make",
      },
      highlight = {
        enable = true,
      },
    },

    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },

  {
    "nvim-mini/mini.icons",
    lazy = true,
    config = function()
      require("mini.icons").setup()
    end,
  },

  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-mini/mini.icons",
    },
    opts = {
      enabled = true,

      render_modes = { "n", "c", "t" },

      completions = {
        lsp = {
          enabled = false,
        },
      },
    },
    keys = {
      {
        "<leader>mr",
        function()
          require("render-markdown").toggle()
        end,
        desc = "Toggle markdown render",
      },
      {
        "<leader>mv",
        function()
          require("render-markdown").preview()
        end,
        desc = "Markdown side preview",
      },
    },
  },
}
