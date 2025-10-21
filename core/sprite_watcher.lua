-- core/sprite_watcher.lua
local viewer_core = require("core.viewer_core")

local M = {}
M._connections = {}

local function refresh(viewParams)
  if not viewParams then return end
  require("render.preview_utils").queuePreview(viewParams, "spritechange")
end

local function hook(appEvents, eventName, handler)
  local ok, conn = pcall(function() return appEvents:on(eventName, handler) end)
  if ok and conn then M._connections[#M._connections+1] = conn end
end

function M.start(viewParams)
  M.stop()
  local events = app.events
  if not events then
    print("[spriteWatcher] app.events not available.")
    return
  end
  local function handler() refresh(viewParams) end
  local names = {
    "change","sitechange","spritechange","celchange","layerchange",
    "framechange","palettechange","selectionchange","tagchange","userdatachange","tilesetchange"
  }
  for _,n in ipairs(names) do hook(events, n, handler) end
end

function M.stop()
  for _,conn in ipairs(M._connections) do pcall(function() if conn.close then conn:close() end end) end
  M._connections = {}
end

return M