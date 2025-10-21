-- dialog/animation_dialog.lua
-- UI only; delegates computation to animation_logic

local logic = require("dialog.utils.animation_logic")
local math_utils = require("utils.math_utils")
local previewRenderer = require("previewRenderer")

local M = {}

function M.open(viewParams, voxelModel, modelDimensions)
  if not voxelModel or #voxelModel == 0 then app.alert("No model to animate!"); return end
  local dlg = Dialog("Create Animation")
  local fovText = (viewParams.orthogonalView and "Ortho") or string.format("FOV: %.0f°", viewParams.fovDegrees or 45)
  dlg:label{ id="current", text=string.format("Euler X: %.0f  Y: %.0f  Z: %.0f   Scale: %.0f%%   %s",
                        viewParams.xRotation or 0, viewParams.yRotation or 0, viewParams.zRotation or 0,
                        (viewParams.scaleLevel or 1)*100, fovText) }
  dlg:separator()
  dlg:combobox{ id="axis", label="Rotation Axis:", options={"X","Y","Z","Pitch","Yaw","Roll"}, option="Y" }
  dlg:combobox{
    id="steps", label="Steps:",
    options={"4","6","8","9","10","12","15","18","20","24","30","36","40","45","60","72","90","120","180","360"}, option="36",
    onchange=function()
      local steps = tonumber(dlg.data.steps) or 36
      local total = tonumber(dlg.data.span) or 360
      local dps = logic.degreesPerStep(total, steps)
      dlg:modify{ id="info", text=string.format("%.2f° per step, %d ms/frame", dps, logic.frameDurationMs(steps)) }
    end
  }
  dlg:slider{
    id="start", label="Start:", min=0, max=359, value=0,
    onchange=function()
      local steps = tonumber(dlg.data.steps) or 36
      local total = tonumber(dlg.data.span) or 360
      local dps = logic.degreesPerStep(total, steps)
      dlg:modify{ id="info", text=string.format("%.2f° per step, %d ms/frame", dps, logic.frameDurationMs(steps)) }
    end
  }
  dlg:slider{
    id="span", label="Span:", min=1, max=360, value=360,
    onchange=function()
      local steps = tonumber(dlg.data.steps) or 36
      local total = tonumber(dlg.data.span) or 360
      local dps = logic.degreesPerStep(total, steps)
      dlg:modify{ id="info", text=string.format("%.2f° per step, %d ms/frame", dps, logic.frameDurationMs(steps)) }
    end
  }
  dlg:label{ id="info", text="10.00° per step, 40 ms/frame" }
  dlg:separator()
  dlg:button{
    text="Create Animation", focus=true,
    onclick=function()
      local steps = tonumber(dlg.data.steps) or 36
      local startAngle = tonumber(dlg.data.start) or 0
      local total = tonumber(dlg.data.span) or 360
      local perStep = total / steps
      local baseMatrix = viewParams.rotationMatrix or math_utils.createRotationMatrix(viewParams.xRotation or 0, viewParams.yRotation or 0, viewParams.zRotation or 0)
      local canvasSize = 300
      if modelDimensions then
        local d = math.sqrt(modelDimensions.sizeX^2 + modelDimensions.sizeY^2 + modelDimensions.sizeZ^2)
        canvasSize = math.max(150, math.floor(d * 5))
      end
      local animSprite = Sprite(canvasSize, canvasSize, ColorMode.RGB)
      app.transaction(function()
        animSprite:deleteLayer("Layer 1")
        local layer = animSprite:newLayer(); layer.name = "Voxel Model"
        for frame=0,steps-1 do
          if frame>0 then animSprite:newFrame() end
          local angle = startAngle + frame * perStep
          local fm = logic.buildFrameMatrix(baseMatrix, dlg.data.axis, angle)
          local e = math_utils.matrixToEuler(fm)
          local params = {
            x=e.x,y=e.y,z=e.z,
            fovDegrees=viewParams.fovDegrees or 45,
            orthogonal=viewParams.orthogonalView,
            perspectiveScaleRef=viewParams.perspectiveScaleRef or "middle",
            pixelSize=1, middlePoint=modelDimensions, canvasSize=viewParams.canvasSize,
            sprite=app.activeSprite, scaleLevel=viewParams.scaleLevel,
            fxStack=viewParams.fxStack, shadingMode=viewParams.shadingMode, lighting=viewParams.lighting, viewDir={0,0,1}
          }
          local img = previewRenderer.renderVoxelModel(voxelModel, params)
          local cel = animSprite:newCel(layer, frame+1, img)
          cel.position = Point(math.floor((canvasSize - img.width)/2), math.floor((canvasSize - img.height)/2))
          animSprite.frames[frame+1].duration = logic.frameDurationMs(steps) / 1000
        end
        animSprite.filename = "animation_"..tostring(dlg.data.axis or "Y")
      end)
      app.activeSprite = animSprite
      app.command.PlayAnimation()
      app.alert(string.format("Animation created with %d frames (%.2f° per frame, %d ms/frame)", steps, perStep, logic.frameDurationMs(steps)))
      dlg:close()
    end
  }
  dlg:button{ text="Cancel", onclick=function() dlg:close() end }
  dlg:show{ wait=true }
end

return M