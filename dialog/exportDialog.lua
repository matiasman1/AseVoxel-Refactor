-- Consolidated export dialog using original structure and previewRenderer for mini preview
local previewRenderer = require("render.previewRenderer")

local exportDialog = {}

function exportDialog.open()
  local dlg = Dialog("Export Options")
  local sprite = app.activeSprite
  local voxelModel = nil
  local previewImage = nil

  local viewParams = { scaleLevel = 1.0 }
  local exportOptions = {
    format = "obj",
    includeTexture = true,
    scaleModel = 1.0,
    optimizeMesh = true
  }

  local canvasWidth, canvasHeight = 160, 160

  local function generatePreview()
    if not sprite then return end
    local regenerated = previewRenderer.generateVoxelModel(sprite)
    if not regenerated or #regenerated == 0 then
      dlg:modify{ id = "modelInfo_count", text = "Voxel count: (No voxels found)" }
      dlg:modify{ id = "modelInfo_dims",  text = "" }
      previewImage = nil
      dlg:repaint()
      return
    end
    voxelModel = regenerated
    local middlePoint = previewRenderer.calculateMiddlePoint(voxelModel)

    local params = {
      x = 315, y = 324, z = 29,
      depth = 50, orthogonal = false,
      pixelSize = 1, canvasSize = canvasWidth, zoomFactor = 1
    }
    previewImage = previewRenderer.renderVoxelModel(voxelModel, params)

    dlg:modify{ id = "modelInfo_count", text = "Voxel count: " .. #voxelModel }
    dlg:modify{
      id = "modelInfo_dims",
      text = string.format("Model size: %dx%dx%d voxels", middlePoint.sizeX, middlePoint.sizeY, middlePoint.sizeZ)
    }
    dlg:repaint()
  end

  dlg:canvas{
    id = "previewCanvas",
    width = canvasWidth, height = canvasHeight,
    onpaint = function(ev)
      local ctx = ev.context
      if not previewImage then generatePreview() end
      if previewImage then
        local ox = math.floor((canvasWidth - previewImage.width)/2)
        local oy = math.floor((canvasHeight - previewImage.height)/2)
        ctx:drawImage(previewImage, ox, oy)
      end
    end
  }

  dlg:newrow()
  dlg:label{ id="modelInfo_count", text="Voxel count: -" }
  dlg:newrow()
  dlg:label{ id="modelInfo_dims", text="" }
  dlg:newrow()

  dlg:button{ id="refresh", text="Refresh", onclick=generatePreview }
  dlg:button{ id="close", text="Close", onclick=function() dlg:close() end }

  dlg:show{ wait=false }
  return dlg
end

return exportDialog