-- viewerCore.lua (refactor): central orchestration of preview updates and metrics
local previewRenderer = require("render.previewRenderer")
local dialogueManager = require("dialog.dialogueManager")

local viewerCore = {}
local _lastMetrics = nil

local function nowMs()
  return os.clock() * 1000
end

-- Render and return an image; also returns voxelModel and middlePoint
function viewerCore.renderPreview(viewParams, context)
  local sprite = app.activeSprite
  if not sprite then return nil end

  local voxelModel = previewRenderer.generateVoxelModel(sprite)
  if not voxelModel or #voxelModel == 0 then return nil end

  local middlePoint = previewRenderer.calculateMiddlePoint(voxelModel)

  local renderParams = {
    xRotation = viewParams.xRotation,
    yRotation = viewParams.yRotation,
    zRotation = viewParams.zRotation,
    fovDegrees = viewParams.fovDegrees or (viewParams.depthPerspective and (5 + (75-5)*(viewParams.depthPerspective/100))) or 45,
    orthogonal = viewParams.orthogonalView,
    perspectiveScaleRef = viewParams.perspectiveScaleRef or "middle",
    enableOutline = viewParams.enableOutline,
    outlineColor = viewParams.outlineColor,
    outlinePattern = viewParams.outlinePattern,
    scaleLevel = viewParams.scaleLevel,
    canvasSize = viewParams.canvasSize or 200,
    pixelSize = 1,
    sprite = sprite,
    middlePoint = middlePoint,
    shadingMode = viewParams.shadingMode or "Stack",
    fxStack = viewParams.fxStack,
    metrics = {}
  }

  local t0 = nowMs()
  local image = previewRenderer.renderVoxelModel(voxelModel, renderParams)
  local t1 = nowMs()

  renderParams.metrics = renderParams.metrics or {}
  renderParams.metrics.renderTime = renderParams.metrics.renderTime or (t1 - t0)
  renderParams.metrics.t_total_ms = renderParams.metrics.t_total_ms or renderParams.metrics.renderTime
  _lastMetrics = renderParams.metrics

  -- Optional UI sync back to controls dialog (e.g., scale label)
  if dialogueManager and dialogueManager.controlsDialog then
    pcall(function()
      dialogueManager.controlsDialog:modify{
        id="scaleLabel",
        text="Scale: " .. string.format("%.0f%%", (viewParams.scaleLevel or 1)*100)
      }
    end)
  end

  return image, voxelModel, middlePoint
end

function viewerCore.updatePreviewCanvas(dlg, viewParams)
  local img = viewerCore.renderPreview(viewParams)
  if dlg and img then
    pcall(function() dlg:repaint() end)
  end
  return img
end

function viewerCore.getLastMetrics()
  return _lastMetrics
end

return viewerCore