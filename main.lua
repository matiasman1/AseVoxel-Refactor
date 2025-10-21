-- main.lua (bootstrap + single AseVoxel command)
local function addLuaCPath(plugin, subfolder)
  local path = app.fs.joinPath(app.fs.userConfigPath, "extensions", plugin.name, subfolder, "?.lua")
  if not package.cpath:find(path, 1, true) then
    package.cpath = path .. ";" .. package.cpath
  end
end

local function addLuaPath(plugin, subfolder)
  local path = app.fs.joinPath(app.fs.userConfigPath, "extensions", plugin.name, subfolder, "?.lua")
  if not package.path:find(path, 1, true) then
    package.path = path .. ";" .. package.path
  end
end

local function setupModuleSearch(plugin)
  local folders = {
    "core",
    "render",
    app.fs.joinPath("render","local"),
    "dialog",
    app.fs.joinPath("dialog","utils"),
    "utils",
    "bin",
  }
  for _, f in ipairs(folders) do
    addLuaPath(plugin, f)
    addLuaCPath(plugin, f)
  end
end

function init(plugin)
  setupModuleSearch(plugin)
  local controller = require("core.controller")

  plugin:newCommand{
    id = "AseVoxel",
    title = "AseVoxel",
    group = "edit_transform",
    onclick = function()
      if not app.activeSprite then
        app.alert("Please open a sprite first!")
        return
      end
      controller.openViewer()
    end
  }
  print("AseVoxel extension initialized!")
end

function exit(plugin)
  print("AseVoxel extension unloaded")
end
