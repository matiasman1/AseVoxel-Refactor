-- main.lua
-- Bootstrap: extend package.cpath with new folders and their subfolders before requiring modelViewer
local function addFoldersToCPath(plugin)
  local extRoot = app.fs.joinPath(app.fs.userConfigPath, "extensions", plugin.name)

  local function tryAppendCPath(dir)
    -- Detect platform-specific shared lib extension(s)
    local isWindows = (package.config:sub(1,1) == "\\")
    local patterns = {}
    if isWindows then
      patterns = {
        app.fs.joinPath(dir, "?.dll"),
        app.fs.joinPath(dir, "loadall.dll"),
        app.fs.joinPath(dir, "*", "?.dll")
      }
    else
      -- Try .so and .dylib
      patterns = {
        app.fs.joinPath(dir, "?.so"),
        app.fs.joinPath(dir, "?.dylib"),
        app.fs.joinPath(dir, "?.lua"),
        app.fs.joinPath(dir, "loadall.so"),
        app.fs.joinPath(dir, "*", "?.so"),
        app.fs.joinPath(dir, "*", "?.dylib"),
        app.fs.joinPath(dir, "*", "?.lua")        
      }
    end
    for _,pat in ipairs(patterns) do
      package.cpath = (package.cpath or "") .. ";" .. pat
      package.path = (package.path or "") .. ";" .. pat
    end
  end

  -- Add top-level folders and immediate subfolders commonly used by the refactor
  local folders = {
    "bin",
    "native",
    "core",
    "dialog",
    "render",
    app.fs.joinPath("render", "preview"),
    "fx",
    "utils"
  }

  for _,folder in ipairs(folders) do
    local abs = app.fs.joinPath(extRoot, folder)
    tryAppendCPath(abs)
  end
end

function init(plugin)
  -- Add cpath entries before requiring any modules
  pcall(function() addFoldersToCPath(plugin) end)

  local modelviewerOK,modelViewer = pcall(require,"modelViewer")

  print(modelViewer)
  print(modelviewerOK)

  if not modelviewerOK or not modelViewer then
    app.alert("Failed to load AseVoxel core module. Please ensure the native library is available.\n\n(AseVoxel will be disabled.)")
    return
  end

  plugin:newCommand{
    id = "AseVoxel",
    title = "AseVoxel",
    group = "edit_transform",
    onclick = function()
      if not app.activeSprite then
        app.alert("Please open a sprite first!")
        return
      end
      modelViewer.openModelViewer()
    end
  }

  print("AseVoxel-Refactor initialized")
end

function exit(plugin)
  print("AseVoxel-Refactor unloaded")
end