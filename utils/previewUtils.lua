-- Thin delegate to render preview with current rotation settings
local previewRenderer = require("render.previewRenderer")
local mathUtils = require("utils.mathUtils")
local rotation = require("utils.rotation")

local previewUtils = {}

function previewUtils.updatePreview(dlg, params)
  local sprite = app.activeSprite
  if not sprite then
    app.alert("No active sprite found!")
    return nil
  end

  local voxelModel = previewRenderer.generateVoxelModel(sprite)
  if #voxelModel == 0 then
    app.alert("No voxels found in the sprite layers!")
    return nil
  end

  local middlePoint = previewRenderer.calculateMiddlePoint(voxelModel)

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
    scaleLevel = params.scaleLevel / 8
  }

  local previewImage = previewRenderer.renderVoxelModel(voxelModel, renderParams)
  dlg:repaint()

  dlg:modify{
    id = "modelInfo",
    text = "Voxel count: " .. #voxelModel ..
           "\nModel size: " .. middlePoint.sizeX .. "×" .. middlePoint.sizeY .. "×" .. middlePoint.sizeZ .. " voxels\n"
  }

  return previewImage
end

return previewUtils