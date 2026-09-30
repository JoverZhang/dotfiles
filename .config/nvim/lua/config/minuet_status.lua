local M = {}

local frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local timer
local generation = 0
local active_kind
local edit_started_at
local edit_started_from_key = false

local function label(kind)
  if kind == "Edit" then
    return string.format("%.2fs", (vim.uv.hrtime() - edit_started_at) / 1e9)
  end
  return kind
end

local function stop_timer()
  if timer and not timer:is_closing() then
    timer:stop()
    timer:close()
  end
  timer = nil
end

local function display(text)
  vim.g.minuet_statusline_text = text
  vim.cmd.redrawstatus()
end

local function start(kind)
  generation = generation + 1
  local request_generation = generation
  active_kind = kind
  edit_started_at = kind == "Edit" and vim.uv.hrtime() or nil
  if kind ~= "Edit" then
    edit_started_from_key = false
  end
  stop_timer()

  local frame = 1
  display("Minuet " .. frames[frame] .. " " .. label(kind))
  timer = vim.uv.new_timer()
  timer:start(120, 120, vim.schedule_wrap(function()
    if generation ~= request_generation then
      return
    end
    frame = frame % #frames + 1
    display("Minuet " .. frames[frame] .. " " .. label(kind))
  end))
end

function M.begin_edit()
  start("Edit")
  edit_started_from_key = true
end

local function finish(kind, visible)
  if active_kind ~= kind then
    return
  end
  generation = generation + 1
  local request_generation = generation
  active_kind = nil
  edit_started_from_key = false
  stop_timer()

  -- Both frontends render their previews after the Finished event fires.
  vim.defer_fn(function()
    if generation ~= request_generation then
      return
    end
    display("Minuet " .. (visible() and "✓" or "–") .. " " .. label(kind))
  end, 80)
end

function M.setup(completion, duet)
  generation = generation + 1
  active_kind = nil
  edit_started_at = nil
  edit_started_from_key = false
  stop_timer()
  display("Minuet ·")

  local segment = "%{get(g:,'minuet_statusline_text','')}"
  if not vim.o.statusline:find("minuet_statusline_text", 1, true) then
    if vim.o.statusline == "" then
      vim.o.statusline = "%f %m%r%h%w%=" .. segment .. " %y %l:%c"
    else
      vim.o.statusline = vim.o.statusline .. " %=" .. segment
    end
  end
  vim.o.laststatus = 3

  local group = vim.api.nvim_create_augroup("MinuetStatusline", { clear = true })
  for _, item in ipairs({
    { started = "MinuetRequestStarted", finished = "MinuetRequestFinished", kind = "Tab", visible = completion.is_visible },
    { started = "MinuetDuetRequestStarted", finished = "MinuetDuetRequestFinished", kind = "Edit", visible = duet.is_visible },
  }) do
    vim.api.nvim_create_autocmd("User", {
      group = group,
      pattern = item.started,
      callback = function()
        if item.kind == "Edit" and edit_started_from_key then
          edit_started_from_key = false
        else
          start(item.kind)
        end
      end,
    })
    vim.api.nvim_create_autocmd("User", {
      group = group,
      pattern = item.finished,
      callback = function()
        finish(item.kind, item.visible)
      end,
    })
  end

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = stop_timer,
  })
end

return M
