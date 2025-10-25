-- Entry point for AseVoxel-Refactor
local modelViewer = require("core.modelViewer")

function init(plugin)
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