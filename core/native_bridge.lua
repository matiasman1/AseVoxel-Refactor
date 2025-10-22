-- core/native_bridge.lua
-- Wrapper for native acceleration library with graceful fallbacks

local debug = require("core.debug")

local nativeBridge = {
  _mod = nil,
  _loaded = false,
  _forceDisabled = false
}

-- Try to load the native module from various locations
local function tryRequire()
  if nativeBridge._loaded then return nativeBridge._mod end
  
  local candidates = {
    "AseVoxelNative",
    "native.AseVoxelNative",
    "bin.AseVoxelNative",
    "lib.AseVoxelNative"
  }
  
  for _, name in ipairs(candidates) do
    local ok, mod = pcall(require, name)
    if ok and mod then
      debug.log("Native bridge loaded from: " .. name)
      nativeBridge._mod = mod
      nativeBridge._loaded = true
      return mod
    end
  end
  
  debug.log("Native bridge not found")
  return nil
end

-- Get the module, trying to load it if needed
local function mod()
  if not nativeBridge._mod then tryRequire() end
  return nativeBridge._mod
end

-- Load native libraries from a specific plugin path
function nativeBridge.loadnative(plugin_path)
  if not plugin_path then return false end
  
  local isWin = package.config:sub(1,1) == '\\'
  local sep = isWin and '\\' or '/'
  
  local candidates = {
    plugin_path,
    plugin_path .. sep .. "bin",
    plugin_path .. sep .. "lib"
  }
  
  -- De-duplicate paths
  local seen = {}
  local filtered = {}
  for _, path in ipairs(candidates) do
    if not seen[path] then
      seen[path] = true
      table.insert(filtered, path)
    end
  end
  
  -- Add paths to package.cpath
  local patterns = {}
  if isWin then
    patterns = {
      plugin_path .. sep .. "?.dll",
      plugin_path .. sep .. "bin" .. sep .. "?.dll"
    }
  else
    patterns = {
      plugin_path .. sep .. "?.so",
      plugin_path .. sep .. "bin" .. sep .. "?.so"
    }
  end
  
  for _, pattern in ipairs(patterns) do
    if not package.cpath:find(pattern, 1, true) then
      package.cpath = pattern .. ";" .. package.cpath
    end
  end
  
  return tryRequire() ~= nil
end

function nativeBridge.isAvailable()
  if nativeBridge._forceDisabled then return false end
  return mod() ~= nil
end

function nativeBridge.setForceDisabled(v)
  nativeBridge._forceDisabled = not not v
end

function nativeBridge.getStatus()
  return {
    available = nativeBridge.isAvailable(),
    loaded = nativeBridge._loaded,
    forceDisabled = nativeBridge._forceDisabled
  }
end

function nativeBridge.transformVoxel(voxel, params)
  local m = mod()
  if not m or not m.transformVoxel then return nil, "Not available" end
  
  local ok, result = pcall(function()
    return m.transformVoxel(voxel, params)
  end)
  
  if not ok then
    debug.log("Native transformVoxel failed: " .. tostring(result))
    return nil, result
  end
  
  return result
end

function nativeBridge.calculateFaceVisibility(voxel, cameraPos, orthogonal, rotationParams)
  local m = mod()
  if not m or not m.calculateFaceVisibility then return nil, "Not available" end
  
  local ok, result = pcall(function()
    return m.calculateFaceVisibility(voxel, cameraPos, orthogonal, rotationParams)
  end)
  
  if not ok then
    debug.log("Native calculateFaceVisibility failed: " .. tostring(result))
    return nil, result
  end
  
  return result
end

function nativeBridge.renderBasic(voxels, params)
  local m = mod()
  if not m or not m.renderBasic then return nil, "Not available" end
  
  local ok, result = pcall(function()
    return m.renderBasic(voxels, params)
  end)
  
  if not ok then
    debug.log("Native renderBasic failed: " .. tostring(result))
    return nil, result
  end
  
  return result
end

function nativeBridge.renderStack(voxels, params)
  local m = mod()
  if not m or not m.renderStack then return nil, "Not available" end
  
  local ok, result = pcall(function()
    return m.renderStack(voxels, params)
  end)
  
  if not ok then
    debug.log("Native renderStack failed: " .. tostring(result))
    return nil, result
  end
  
  return result
end

function nativeBridge.renderDynamic(voxels, params)
  local m = mod()
  if not m or not m.renderDynamic then return nil, "Not available" end
  
  local ok, result = pcall(function()
    return m.renderDynamic(voxels, params)
  end)
  
  if not ok then
    debug.log("Native renderDynamic failed: " .. tostring(result))
    return nil, result
  end
  
  return result
end

function nativeBridge.unloadAll()
  if not nativeBridge._loaded then return true end
  
  local m = nativeBridge._mod
  if m then
    if m.unload then
      local ok, err = pcall(function() m.unload() end)
      if not ok then
        debug.log("Native unload failed: " .. tostring(err))
      end
    end
  end
  
  nativeBridge._mod = nil
  nativeBridge._loaded = false
  
  return true
end

-- Also provide a small explicit alias
function nativeBridge.unloadNative()
  return nativeBridge.unloadAll()
end

return nativeBridge