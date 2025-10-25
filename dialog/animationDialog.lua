-- Split from dialogUtils.openAnimationDialog (preserves UI intent)
local rotation = require("utils.rotation")

local animationDialog = {}

function animationDialog.open(viewParams, modelDimensions, voxelModel, canvasSize, scaleLevel)
  local vp = viewParams or {}
  local dlg = Dialog("Create Animation")

  dlg:label{
    id = "currentEulerLabel",
    text = string.format(
      "Current position (Euler)  X: %.0f  Y: %.0f  Z: %.0f",
      (vp.xRotation or vp.eulerX or 0),
      (vp.yRotation or vp.eulerY or 0),
      (vp.zRotation or vp.eulerZ or 0)
    )
  }
  dlg:newrow()

  -- Additional controls can be ported here as needed
  dlg:button{ id="close", text="Close", onclick=function() dlg:close() end }

  dlg:show{ wait=false }
  return dlg
end

return animationDialog