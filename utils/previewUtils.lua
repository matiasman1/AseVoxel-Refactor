-- previewUtils.lua: update preview and create animations
local previewRenderer = require("render.previewRenderer")

local previewUtils = {}

-- Update preview canvas with current parameters
function previewUtils.updatePreview(dlg, params)
  local sprite = app.activeSprite
  if not sprite then
    app.alert("No active sprite found!")
    return nil
  end

  local model = previewRenderer.generateVoxelModel(sprite)
  if not model or #model == 0 then
    app.alert("No voxels found in the sprite layers!")
    return nil
  end

  local middlePoint = previewRenderer.calculateMiddlePoint(model)
  local renderParams = {
    x = params.xRotation,
    y = params.yRotation,
    z = params.zRotation,
    fovDegrees = params.fovDegrees or params.fov or (params.depthPerspective and (5 + (75-5)*(params.depthPerspective/100))) or 45,
    orthogonal = params.orthogonalView,
    pixelSize = 1,
    middlePoint = middlePoint,
    canvasSize = params.canvasSize,
    sprite = sprite,
    scaleLevel = params.scaleLevel
  }

  local img = previewRenderer.renderVoxelModel(model, renderParams)
  if dlg and img then pcall(function() dlg:repaint() end) end

  if dlg then
    pcall(function()
      dlg:modify{
        id = "modelInfo",
        text = "Voxel count: " .. #model ..
               "\nModel size: " .. middlePoint.sizeX .. "×" .. middlePoint.sizeY .. "×" .. middlePoint.sizeZ .. " voxels\n"
      }
    end)
  end

  return img
end

-- Create a simple turntable animation by rotating around an axis
-- params: xRotation, yRotation, zRotation, animationAxis, animationSteps, canvasSize, scaleLevel, shadingMode, orthogonalView, fovDegrees/depthPerspective
function previewUtils.createAnimation(params)
  local sprite = app.activeSprite
  if not sprite then
    app.alert("Open a sprite first")
    return false
  end
  local axis = (params.animationAxis or "Y"):upper()
  local steps = tonumber(params.animationSteps) or 36
  local totalRotation = tonumber(params.totalRotation) or 360
  if steps <= 0 then steps = 1 end
  local perStep = totalRotation / steps
  local frameDuration = math.ceil(1440 / steps)

  local baseFilename = (sprite.filename ~= "" and sprite.filename) or "voxel"
  local animSprite = Sprite(params.canvasSize or 200, params.canvasSize or 200, ColorMode.RGBA)
  animSprite.filename = baseFilename .. "_" .. axis

  app.transaction(function()
    for frame = 0, steps - 1 do
      local angleX = params.xRotation or 0
      local angleY = params.yRotation or 0
      local angleZ = params.zRotation or 0
      if axis == "X" or axis == "PITCH" then angleX = (angleX + frame * perStep) % 360 end
      if axis == "Y" or axis == "YAW"   then angleY = (angleY + frame * perStep) % 360 end
      if axis == "Z" or axis == "ROLL"  then angleZ = (angleZ + frame * perStep) % 360 end

      local model = previewRenderer.generateVoxelModel(sprite)
      if not model or #model == 0 then break end
      local mp = previewRenderer.calculateMiddlePoint(model)

      local rp = {
        x = angleX, y = angleY, z = angleZ,
        fovDegrees = params.fovDegrees or (params.depthPerspective and (5 + (75-5)*(params.depthPerspective/100))) or 45,
        orthogonal = params.orthogonalView,
        pixelSize = 1,
        middlePoint = mp,
        canvasSize = params.canvasSize or 200,
        sprite = sprite,
        scaleLevel = params.scaleLevel or 1.0,
        shadingMode = params.shadingMode or "Stack",
        fxStack = params.fxStack
      }

      local frameImage = previewRenderer.renderVoxelModel(model, rp)
      if frame > 0 then animSprite:newFrame() end
      local cel = animSprite:newCel(animSprite.layers[1], frame + 1, frameImage, Point(0,0))
      cel.position = Point(
        math.floor(((rp.canvasSize or 200) - frameImage.width) / 2),
        math.floor(((rp.canvasSize or 200) - frameImage.height) / 2)
      )
      animSprite.frames[frame + 1].duration = frameDuration / 1000
    end
  end)

  app.activeSprite = animSprite
  app.command.PlayAnimation()
  app.alert(string.format(
    "Animation created with %d frames (%.2f° per frame, total %d°, %d ms/frame)",
    steps, perStep, totalRotation, frameDuration
  ))
  return true
end

return previewUtils