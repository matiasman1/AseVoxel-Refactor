-- Remote/native accelerated renderer bridge
local nativeBridge_ok, nativeBridge = pcall(require, "native.nativeBridge")

local RemoteRenderer = {}

-- model: array of voxels { x,y,z, color={r,g,b,a} }
-- params: width,height, rotations, scale, orthogonal, shadingMode, lighting, fxStack, backgroundColor, etc.
-- _metrics: optional table to record backend info
function RemoteRenderer.nativeRender(model, params, _metrics)
  if not nativeBridge or not nativeBridge.isAvailable or not nativeBridge.isAvailable() then
    return nil, "native not available"
  end
  if not model or #model == 0 then return nil, "empty model" end

  -- Build flat voxel list [x,y,z,r,g,b,a]
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

  -- Delegate to native bridge (API surface depends on native lib; stubbed here)
  if nativeBridge.render then
    return nativeBridge.render(flat, params, _metrics)
  end

  return nil, "native bridge missing render()"
end

return RemoteRenderer