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
bindKittySwitcher('1', 0.7)
bindKittySwitcher('2', 1)
