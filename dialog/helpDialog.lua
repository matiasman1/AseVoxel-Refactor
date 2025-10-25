-- Identical help dialog content from original dialogUtils.openHelpDialog
local helpDialog = {}

function helpDialog.open()
  local dlg = Dialog("Voxel Model Viewer Help")

  dlg:label{ id = "helpLine1", text = "Voxel Model Viewer" }
  dlg:newrow()
  dlg:label{ id = "helpLine2", text = "" }
  dlg:newrow()
  dlg:label{ id = "helpLine3", text = "Controls:" }
  dlg:newrow()
  dlg:label{ id = "helpLine4", text = "- Left-click and drag to use trackball rotation" }
  dlg:newrow()
  dlg:label{ id = "helpLine5", text = "- Right-click and drag to adjust depth perspective" }
  dlg:newrow()
  dlg:label{ id = "helpLine6", text = "- Mouse wheel to zoom (scale)" }
  dlg:newrow()
  dlg:label{ id = "helpLine7", text = "" }
  dlg:newrow()
  dlg:label{ id = "helpLine8", text = "Dialogs:" }
  dlg:newrow()
  dlg:label{ id = "helpLine9", text = "- Controls: Adjust Euler angles, FOV, scale, shading" }
  dlg:newrow()
  dlg:label{ id = "helpLine10", text = "- Preview: Shows the 3D voxel rendering" }
  dlg:newrow()
  dlg:label{ id = "helpLine21", text = "For more help visit:" }
  dlg:newrow()
  dlg:label{ id = "helpLine22", text = "https://github.com/mattiasgustavsson/voxelmaker" }

  dlg:button{
    id = "closeBtn",
    text = "Close",
    focus = true,
    onclick = function() dlg:close() end
  }

  dlg:show{ wait = true }
  return dlg
end

return helpDialog