local spaces = require("hs.spaces") -- https://github.com/asmagill/hs._asm.spaces
local kittyBundleID = 'net.kovidgoyal.kitty' -- more accurate to avoid mismatching on browser titles

local function getMainWindow(app)
  local win = nil
  while win == nil do
    win = app:mainWindow()
  end
  return win
end

local function moveWindowToCurrentSpace(app, space, mainScreen, widthRatio)
  local win = getMainWindow(app)
  if win:isFullScreen() then
    hs.eventtap.keyStroke('fn', 'f', 0, app)
  end

  local winFrame = win:frame()
  local scrFrame = mainScreen:fullFrame()
  winFrame.w = scrFrame.w * widthRatio
  winFrame.y = scrFrame.y
  winFrame.x = scrFrame.x
  win:setFrame(winFrame, 0)
  spaces.moveWindowToSpace(win, space)

  if win:isFullScreen() then
    hs.eventtap.keyStroke('fn', 'f', 0, app)
  end
  win:focus()
end

local function bindKittySwitcher(key, widthRatio)
  hs.hotkey.bind({'command', 'ctrl'}, key, function ()
    local kitty = hs.application.get(kittyBundleID)
    if kitty ~= nil and kitty:isFrontmost() then
      kitty:hide()
    else
      local space = spaces.activeSpaceOnScreen()
      local mainScreen = hs.screen.mainScreen()
      if kitty == nil and hs.application.launchOrFocusByBundleID(kittyBundleID) then
        local appWatcher = nil
        appWatcher = hs.application.watcher.new(function(name, event, app)
          if event == hs.application.watcher.launched and app:bundleID() == kittyBundleID then
            getMainWindow(app):move(hs.geometry({x=0,y=0,w=1,h=0.4}))
            app:hide()
            moveWindowToCurrentSpace(app, space, mainScreen, widthRatio)
            appWatcher:stop()
          end
        end)
        appWatcher:start()
      end
      if kitty ~= nil then
        moveWindowToCurrentSpace(kitty, space, mainScreen, widthRatio)
      end
    end
  end)
end

-- Switch kitty
-- bindKittySwitcher('1', 0.2)
bindKittySwitcher('2', 1)

local templates = {
  {
    icon = "🧪",
    group = "Debug",
    title = "Debug Root Cause",
    desc = "现象 / 预期 / 日志 / 已尝试",
    body = [[
I am debugging the following issue.

Observed behavior:
Expected behavior:
Relevant code:
Logs:
What I have tried:

Please analyze the likely root cause and suggest the next verification steps.
]]
  },
  {
    icon = "🔍",
    group = "Code",
    title = "Code Review",
    desc = "正确性 / 边界 / 可读性 / 性能",
    body = [[
Please review the following code.

Focus on:
1. Correctness
2. Edge cases
3. Readability
4. Performance
5. Potential bugs

Code:
]]
  },
  {
    icon = "📖",
    group = "Explain",
    title = "Explain Code",
    desc = "逐步解释控制流和关键数据结构",
    body = [[
Please explain the following code step by step.

I want to understand:
1. What it does
2. The control flow
3. Important data structures
4. Possible pitfalls

Code:
]]
  }
}

local function pasteText(text)
  hs.pasteboard.setContents(text)

  hs.timer.doAfter(0.06, function()
    hs.eventtap.keyStroke({"cmd"}, "v")
  end)
end

local function buildChoices()
  local choices = {}

  for _, item in ipairs(templates) do
    table.insert(choices, {
      text = string.format("%s  %s", item.icon, item.title),
      subText = string.format("%s  ·  %s", item.group, item.desc),
      body = item.body
    })
  end

  return choices
end

local promptChooser = hs.chooser.new(function(choice)
  if not choice then
    return
  end

  pasteText(choice.body)
end)

promptChooser
  :choices(buildChoices())
  :placeholderText("Search prompt templates...")
  :searchSubText(true)
  :rows(8)
  :width(35)
  :bgDark(true)
  :fgColor({ white = 0.95, alpha = 1 })
  :subTextColor({ white = 0.65, alpha = 1 })

local function showPromptChooser()
  promptChooser:show()
end

hs.hotkey.bind({"ctrl", "cmd"}, "v", showPromptChooser)
hs.hotkey.bind({"ctrl", "alt", "cmd"}, "R", hs.reload)
