-- Native bridge loader: checks /bin for platform libs; optional
local nativeBridge = {}

local function detectPlatform()
  local plat = app and app.os and string.lower(app.os) or ""
  if plat:find("windows") then return "windows" end
  if plat:find("mac") or plat:find("darwin") then return "mac" end
  if plat:find("linux") then return "linux" end
  return "unknown"
end

local function hasFile(path)
  local ok, f = pcall(function() return io.open(path, "rb") end)
  if ok and f then f:close() return true end
  return false
end

local function tryLocateBin()
  -- Look under extension folder ./bin
  local candidates = {}
  local plat = detectPlatform()
  if plat == "windows" then
    table.insert(candidates, "bin/asevoxel_native.dll")
  elseif plat == "mac" then
    table.insert(candidates, "bin/libasevoxel_native.dylib")
  elseif plat == "linux" then
    table.insert(candidates, "bin/libasevoxel_native.so")
  end
  for _,p in ipairs(candidates) do
    if hasFile(p) then return p end
  end
  return nil
end

local _libPath = tryLocateBin()

function nativeBridge.isAvailable()
  return _libPath ~= nil
end

-- Optional: nativeBridge.render(flatVoxels, params, metrics)
-- In Phase 2, bind to actual native shared library through provided Lua-C bridge if available.
-- For now, stubbed.
function nativeBridge.render()
  return nil, "not implemented"
end

return nativeBridge