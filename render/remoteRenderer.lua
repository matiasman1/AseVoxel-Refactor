-- render/remoteRenderer.lua
-- Remote renderer: tries nativeBridge, else optional websocket remote server (graceful fallback).
local json = nil
pcall(function() json = require("json") end) -- optional json
local socket_ok, socket = pcall(require, "socket") -- optional luasocket

local RemoteRenderer = {}
RemoteRenderer._enabled = false
RemoteRenderer._ws = nil
RemoteRenderer._inflight = false
RemoteRenderer._pending = nil
RemoteRenderer._pendingReady = false

-- Try native first: wrapper kept in facade (previewRenderer)
local nativeBridge_ok, nativeBridge = pcall(require, "native.nativeBridge")

function RemoteRenderer.enable(v) RemoteRenderer._enabled = v and true or false end

-- If websockets available, implement connect/communications.
-- Keep minimal implementation for environments where ws not available.
local function ensure_connected(timeout)
  if not RemoteRenderer._enabled then return false end
  -- Placeholder: if user has a ws client library, you can implement transport here.
  return false
end

-- Render: prefer native, else attempt remote if enabled
function RemoteRenderer.nativeRender(model, params, _metrics)
  if not nativeBridge_ok or not nativeBridge then return nil, "native not available" end
  if not model or #model == 0 then return nil, "empty model" end

  local flat = {}
  for i,v in ipairs(model) do
    local c = v.color or {}
    flat[i] = {
      v.x or 0, v.y or 0, v.z or 0,
      math.max(0, math.min(255, c.r or c.red or 255)),
      math.max(0, math.min(255, c.g or c.green or 255)),
      math.max(0, math.min(255, c.b or c.blue or 255)),
      math.max(0, math.min(255, c.a or c.alpha or 255))
    }
  end

  -- Try nativeBridge render variants
  if nativeBridge and nativeBridge.isAvailable and nativeBridge.isAvailable() then
    if params and params.shadingMode == "Stack" and nativeBridge.renderStack then
      return nativeBridge.renderStack(flat, params)
    elseif params and params.shadingMode == "Dynamic" and nativeBridge.renderDynamic then
      return nativeBridge.renderDynamic(flat, params)
    elseif nativeBridge.renderBasic then
      return nativeBridge.renderBasic(flat, params)
    end
  end

  return nil, "no backend"
end

return RemoteRenderer