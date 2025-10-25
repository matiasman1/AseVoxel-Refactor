-- Native bridge loader: checks ./bin for platform libs and attempts loadlib.
-- Phase 2: will integrate with the specific native API if available.
local nativeBridge = {}

local function detectPlatform()
  local plat = ""
  if package.config:sub(1,1) == "\\" then
    plat = "windows"
  else
    plat = "unix"
  end
  -- refine for mac/linux if needed by checking io.popen uname
  return plat
end

local function hasFile(path)
  local ok, f = pcall(function() return io.open(path, "rb") end)
  if ok and f then f:close() return true end
  return false
end

local function tryLocateBin()
  local candidates = {}
  local plat = detectPlatform()
  if plat == "windows" then
    table.insert(candidates, "bin/asevoxel_native.dll")
  else
    -- mac/linux use .so / .dylib heuristics
    table.insert(candidates, "bin/libasevoxel_native.so")
    table.insert(candidates, "bin/libasevoxel_native.dylib")
  end
  for _, p in ipairs(candidates) do
    if hasFile(p) then return p end
  end
  return nil
end

local _libPath = tryLocateBin()
local _loaded = nil
local _attempted = false

function nativeBridge.isAvailable()
  return _libPath ~= nil
end

-- Try to load the native lib with package.loadlib (if allowed); return module table on success
local function loadNative()
  if _attempted then return _loaded end
  _attempted = true
  if not _libPath then return nil end
  -- attempt to require a global symbol loader: we expect the native lib to expose a 'luaopen_asevoxel' style entry
  local entryName = "luaopen_asevoxel_native"
  local ok, lib = pcall(function()
    return package.loadlib(_libPath, entryName)
  end)
  if ok and type(lib) == "function" then
    local success, mod = pcall(lib)
    if success and type(mod) == "table" then
      _loaded = mod
      return _loaded
    end
  end
  return nil
end

function nativeBridge.getModule()
  return loadNative()
end

-- Simple render wrapper: call native render if available
function nativeBridge.render(flatVoxels, params, metrics)
  local m = loadNative()
  if not m then return nil, "native not loaded" end
  if not m.render then return nil, "native missing render()" end
  local ok, res = pcall(m.render, flatVoxels, params, metrics)
  if not ok then return nil, "native render error" end
  return res
end

return nativeBridge