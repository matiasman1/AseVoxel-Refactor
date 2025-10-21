-- dialog/help_dialog.lua
local M = {}

local function line(dlg, id, text) dlg:label{ id=id, text=text }; dlg:newrow() end

function M.open()
  local dlg = Dialog("Voxel Model Viewer Help")
  line(dlg, "h1", "Voxel Model Viewer")
  line(dlg, "s1", "")
  line(dlg, "c1", "Controls:")
  line(dlg, "c2", "- Left-click and drag to use trackball rotation")
  line(dlg, "c3", "- Middle-click and drag for orbit camera")
  line(dlg, "c4", "- Use View Controls dialog for precise angle control")
  line(dlg, "s2", "")
  line(dlg, "l1", "Layers:")
  line(dlg, "l2", "- Each visible layer becomes a Z-level in the 3D model")
  line(dlg, "l3", "- Top layers appear in front (lower Z value)")
  line(dlg, "l4", "- Non-transparent pixels become voxels")
  line(dlg, "s3", "")
  line(dlg, "a1", "Animation:")
  line(dlg, "a2", "- Create animations along X, Y, Z axes or Pitch/Yaw/Roll")
  line(dlg, "a3", "- Set the number of frames and it creates a GIF")
  line(dlg, "s4", "")
  line(dlg, "e1", "Export:")
  line(dlg, "e2", "- Export to OBJ, PLY, or STL formats")
  line(dlg, "e3", "- Materials and colors preserved in OBJ format")
  line(dlg, "s5", "")
  line(dlg, "g1", "For more help visit:")
  line(dlg, "g2", "https://github.com/mattiasgustavsson/voxelmaker")
  dlg:button{ text="Close", focus=true, onclick=function() dlg:close() end }
  dlg:show{ wait=true }
end

return M