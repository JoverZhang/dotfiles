return {
  {
    "milanglacier/minuet-ai.nvim",
    lazy = false,
    config = function()
      -- Set these in the environment before starting Neovim. The URL must be
      -- the full /chat/completions endpoint of the private OpenAI backend.
      local endpoint = vim.env.MINUET_OPENAI_CHAT_COMPLETIONS_URL
      local api_key = vim.env.MINUET_OPENAI_API_KEY
      if not endpoint or endpoint == "" or not api_key or api_key == "" then
        return
      end

      require("minuet").setup({
        provider = "openai",
        n_completions = 1,
        context_window = 8000,
        request_timeout = 10,
        provider_options = {
          openai = {
            model = "gpt-6-luna",
            end_point = endpoint,
            api_key = "MINUET_OPENAI_API_KEY",
            optional = {
              reasoning_effort = "none",
              max_completion_tokens = 128,
            },
          },
        },
        virtualtext = {
          auto_trigger_ft = {},
          keymap = {
            accept_line = "<A-l>",
            next = "<A-y>",
          },
        },
        duet = {
          provider = "openai",
          request_timeout = 30,
          auto_trigger = { auto_trigger_ft = {} },
          provider_options = {
            openai = {
              model = "gpt-6-luna",
              end_point = endpoint,
              api_key = "MINUET_OPENAI_API_KEY",
              optional = { reasoning_effort = "none" },
            },
          },
        },
      })

      -- Minuet's built-in accept mapping consumes Tab when there is no
      -- suggestion, so preserve ordinary Tab behavior explicitly.
      local suggestion = require("minuet.virtualtext").action
      local edit = require("minuet.duet").action
      local status = require("config.minuet_status")
      status.setup(suggestion, edit)

      local original_predict_edit = edit._minuet_original_predict or edit.predict
      edit._minuet_original_predict = original_predict_edit
      edit.predict = function(...)
        status.begin_edit()
        return original_predict_edit(...)
      end

      local original_apply_edit = edit._minuet_original_apply or edit.apply
      edit._minuet_original_apply = original_apply_edit
      local function apply_edit_without_moving_cursor()
        local win = vim.api.nvim_get_current_win()
        local buf = vim.api.nvim_win_get_buf(win)
        local cursor = vim.api.nvim_win_get_cursor(win)

        original_apply_edit()

        if not vim.api.nvim_win_is_valid(win) or vim.api.nvim_win_get_buf(win) ~= buf then
          return
        end
        local row = math.min(cursor[1], vim.api.nvim_buf_line_count(buf))
        local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
        vim.api.nvim_win_set_cursor(win, { row, math.min(cursor[2], #line) })
      end
      edit.apply = apply_edit_without_moving_cursor

      vim.keymap.set("n", "<A-y>", edit.predict, { desc = "Predict Minuet edit" })
      vim.keymap.set("n", "<leader>mp", edit.predict, { desc = "Predict Minuet edit" })
      vim.keymap.set("n", "<leader>ma", apply_edit_without_moving_cursor, { desc = "Apply Minuet edit" })
      vim.keymap.set("n", "<leader>md", edit.dismiss, { desc = "Dismiss Minuet edit" })
      vim.keymap.set("i", "<A-e>", function()
        if edit.is_visible() then
          edit.dismiss()
        else
          suggestion.dismiss()
        end
      end, { desc = "Dismiss Minuet suggestion" })

      vim.keymap.set("i", "<Tab>", function()
        if edit.is_visible() then
          vim.schedule(apply_edit_without_moving_cursor)
          return ""
        end
        if suggestion.is_visible() then
          suggestion.accept()
          return ""
        end
        if vim.snippet.active({ direction = 1 }) then
          return "<Cmd>lua vim.snippet.jump(1)<CR>"
        end
        return "<Tab>"
      end, { expr = true, desc = "Accept AI suggestion or insert Tab" })

      vim.keymap.set("n", "<Tab>", function()
        if edit.is_visible() then
          vim.schedule(apply_edit_without_moving_cursor)
          return ""
        end
        return "<C-i>"
      end, { expr = true, desc = "Apply Minuet edit or jump forward" })
    end,
  },
}
