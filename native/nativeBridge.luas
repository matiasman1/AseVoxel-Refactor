-- native/nativeBridge.lua
-- Enhanced attempt to load native symbols from ./bin and expose expected API.
local nativeBridge = {}

local function detectPlatform()
  if package.config:sub(1,1) == "\\" then return "windows" end
  -- try uname
  local ok, uname = pcall(function() return io.popen and io.popen("uname -s"):read("*l") end)
  if ok and uname then
    uname = uname:lower()
    if uname:find("darwin") then return "mac" end
    if uname:find("linux") then return "linux" end
  end
  return "unix"
end

local function hasFile(path)
  local ok, f = pcall(function() return io.open(path, "rb") end)
  if ok and f then f:close(); return true end
  return false
end

local function locateLib()
  local plat = detectPlatform()
  local candidates = {}
  if plat == "windows" then
    table.insert(candidates, "bin/asevoxel_native.dll")
  elseif plat == "mac" then
    table.insert(candidates, "bin/libasevoxel_native.dylib")
  else
    table.insert(candidates, "bin/libasevoxel_native.so")
  end
  for _,p in ipairs(candidates) do
    if hasFile(p) then return p end
  end
  return nil
end

local _libPath = locateLib()
local _module = nil
local _attempted = false
nativeBridge._loadedPath = _libPath
nativeBridge._attempted = false
nativeBridge._logOnce = {}

local function tryLoad()
  if _attempted then return _module end
  _attempted = true
  nativeBridge._attempted = true
  if not _libPath then return nil end
  -- try package.loadlib expecting luaopen_asevoxel_native symbol
  local entryCandidates = { "luaopen_asevoxel_native", "luaopen_asevoxel" }
  for _,entry in ipairs(entryCandidates) do
    local ok, loader = pcall(function() return package.loadlib(_libPath, entry) end)
    if ok and type(loader) == "function" then
      local ok2, mod = pcall(loader)
      if ok2 and type(mod) == "table" then
        _module = mod
        nativeBridge._loadedPath = _libPath
        return _module
      end
    end
  end
  return nil
end

function nativeBridge.isAvailable()
  return tryLoad() ~= nil
end

function nativeBridge.getModule()
  return tryLoad()
end

-- transformVoxel wrapper (calls native transform if available)
function nativeBridge.transformVoxel(voxel, params)
  local m = tryLoad()
  if not m or not m.transform_voxel then return nil, "native missing" end
  local ok, transformed = pcall(m.transform_voxel, { x = voxel.x, y = voxel.y, z = voxel.z, color = voxel.color }, params or {})
  if not ok then return nil, transformed end
  return transformed
end

-- render wrappers: call native module functions if available
function nativeBridge.renderBasic(voxelsFlat, params)
  local m = tryLoad()
  if not m or not m.render_basic then return nil, "native missing" end
  local ok, res = pcall(m.render_basic, voxelsFlat, params)
  if not ok then return nil, res end
  return res
end

function nativeBridge.renderStack(voxelsFlat, params)
  local m = tryLoad()
  if not m or not m.render_stack then return nil, "native missing" end
  local ok, res = pcall(m.render_stack, voxelsFlat, params)
  if not ok then return nil, res end
  return res
end

function nativeBridge.renderDynamic(voxelsFlat, params)
  local m = tryLoad()
  if not m or not m.render_dynamic then return nil, "native missing" end
  local ok, res = pcall(m.render_dynamic, voxelsFlat, params)
  if not ok then return nil, res end
  return res
end

return nativeBridge