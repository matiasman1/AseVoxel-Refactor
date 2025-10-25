-- Animation dialog: mirrors original AseVoxel options and live info
local previewUtils = require("previewUtils")

local animationDialog = {}

function animationDialog.open(viewParams, modelDimensions, voxelModel, canvasSize, scaleLevel)
  local vp = viewParams or {}
  local dlg = Dialog("Create Animation")

  dlg:label{
    id = "currentEulerLabel",
    text = string.format(
      "Current position (Euler)  X: %.0f  Y: %.0f  Z: %.0f   Scale: %.0f%%   %s",
      (vp.xRotation or vp.eulerX or 0),
      (vp.yRotation or vp.eulerY or 0),
      (vp.zRotation or vp.eulerZ or 0),
      (vp.scaleLevel or 1) * 100,
      ((vp.orthogonalView and "Ortho") or string.format("FOV: %.0f°", vp.fovDegrees or 45))
    )
  }
  dlg:newrow()

  dlg:combobox{
    id = "animationAxis",
    label = "Rotation Axis:",
    options = { "X", "Y", "Z", "Pitch", "Yaw", "Roll" },
    option = "Y"
  }

  dlg:combobox{
    id = "animationSteps",
    label = "Steps:",
    options = {"4","5","6","8","9","10","12","15","18","20","24","30","36","40","45","60","72","90","120","180","360"},
    option = "36",
    onchange = function()
      local steps = tonumber(dlg.data.animationSteps) or 36
      local degreesPerStep = 360 / steps
      local frameDuration = math.ceil(1440 / steps)
      dlg:modify{ id = "stepsInfo", text = string.format("%.2f° per step, %d ms/frame", degreesPerStep, frameDuration) }
    end
  }

  dlg:slider{
    id = "totalRotation",
    label = "Span:",
    min = 1, max = 360, value = 360,
    onchange = function()
      local steps = tonumber(dlg.data.animationSteps) or 36
      local total = tonumber(dlg.data.totalRotation) or 360
      local dps = total / steps
      dlg:modify{ id = "stepsInfo", text = string.format("%.2f° per step, %d ms/frame", dps, math.ceil(1440 / steps)) }
    end
  }

  dlg:label{ id = "stepsInfo", text = "10.00° per step, 40 ms/frame" }
  dlg:separator()

  dlg:button{
    id = "createButton",
    text = "Create Animation",
    focus = true,
    onclick = function()
      local params = {
        xRotation = vp.xRotation, yRotation = vp.yRotation, zRotation = vp.zRotation,
        depthPerspective = vp.depthPerspective,
        fovDegrees = vp.fovDegrees,
        orthogonalView = vp.orthogonalView,
        animationAxis = dlg.data.animationAxis,
        animationSteps = dlg.data.animationSteps,
        totalRotation = dlg.data.totalRotation,
        canvasSize = canvasSize or vp.canvasSize or 200,
        scaleLevel = scaleLevel or vp.scaleLevel or 1.0,
        shadingMode = vp.shadingMode,
        fxStack = vp.fxStack
      }
      previewUtils.createAnimation(params)
      dlg:close()
    end
  }

  dlg:button{ id="close", text="Close", onclick=function() dlg:close() end }
  dlg:show{ wait=false }
  return dlg
end

return animationDialog