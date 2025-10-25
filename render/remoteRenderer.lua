-- remoteRenderer.lua
-- Attempt to use nativeBridge first, otherwise (optionally) connect to remote renderer.
-- For now the remote websocket path is left as a stub; focus is on native integration and compatibility.
local nativeBridge = require("native.nativeBridge")

local RemoteRenderer = {}
RemoteRenderer._enabled = false
RemoteRenderer._connected = false

function RemoteRenderer.enable(v)
  RemoteRenderer._enabled = v and true or false
end

-- Native fast-path: expect array of voxels as {x,y,z,r,g,b,a}
local function tryNativeRender(flat, params, _metrics)
  if nativeBridge and nativeBridge.isAvailable() then
    if params and params.shadingMode == "Stack" and nativeBridge.renderStack then
      local ok, res = pcall(nativeBridge.renderStack, flat, params)
      if ok and res then return res end
    elseif params and params.shadingMode == "Dynamic" and nativeBridge.renderDynamic then
      local ok, res = pcall(nativeBridge.renderDynamic, flat, params)
      if ok and res then return res end
    elseif nativeBridge.renderBasic then
      local ok, res = pcall(nativeBridge.renderBasic, flat, params)
      if ok and res then return res end
    end
  end
  return nil, "native not available"
end

-- model: array of voxels { x,y,z, color={r,g,b,a} }
function RemoteRenderer.nativeRender(model, params, _metrics)
  if not model or #model == 0 then return nil, "empty model" end

  -- build flat array for native API
  local flat = {}
  for i,v in ipairs(model) do
    local c = v.color or {}
    flat[i] = { v.x or 0, v.y or 0, v.z or 0,
                math.max(0, math.min(255, c.r or c.red or 255)),
                math.max(0, math.min(255, c.g or c.green or 255)),
                math.max(0, math.min(255, c.b or c.blue or 255)),
                math.max(0, math.min(255, c.a or c.alpha or 255)) }
  end

  return tryNativeRender(flat, params, _metrics)
end

return RemoteRenderer