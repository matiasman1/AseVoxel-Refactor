-- Core non-UI orchestration for preview rendering
local previewRenderer = require("render.previewRenderer")
local previewUtils = require("utils.previewUtils")

local viewerCore = {}
local _lastMetrics = nil

local function nowMs()
  return os.clock() * 1000
end

-- Render and return an image; caller may pass controlsDialog to sync UI text (scale label, etc.)
function viewerCore.renderPreview(viewParams, context)
  local sprite = app.activeSprite
  if not sprite then return nil end

  -- Generate model once per render call (kept parity with original)
  local voxelModel = previewRenderer.generateVoxelModel(sprite)
  if not voxelModel or #voxelModel == 0 then return nil end

  local middlePoint = previewRenderer.calculateMiddlePoint(voxelModel)

  local params = {
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
  local image = previewRenderer.renderVoxelModel(voxelModel, params)
  local t1 = nowMs()

  params.metrics = params.metrics or {}
  params.metrics.renderTime = params.metrics.renderTime or (t1 - t0)
  params.metrics.t_total_ms = params.metrics.t_total_ms or params.metrics.renderTime
  _lastMetrics = params.metrics

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