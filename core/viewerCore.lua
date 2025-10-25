-- viewerCore.lua: orchestrates rendering, throttling, and UI sync
local previewRenderer = require("render.previewRenderer")
local dialogueManager = require("dialog.dialogueManager")

local viewerCore = {}
local _lastMetrics = nil
local _throttle = { multiplier = 2.5, minMs = 30, maxMs = 5000 }
local _lastRenderAt = 0

local function nowMs() return os.clock() * 1000 end

function viewerCore.setAdaptiveThrottle(cfg)
  _throttle.multiplier = cfg.multiplier or _throttle.multiplier
  _throttle.minMs = cfg.minMs or _throttle.minMs
  _throttle.maxMs = cfg.maxMs or _throttle.maxMs
end

local function shouldThrottle()
  local dt = nowMs() - _lastRenderAt
  local minInterval = _throttle.minMs
  return dt < minInterval
end

function viewerCore.renderPreview(viewParams, context)
  if shouldThrottle() then return nil end
  local sprite = app.activeSprite
  if not sprite then return nil end

  local model = previewRenderer.generateVoxelModel(sprite)
  if not model or #model == 0 then return nil end

  local mp = previewRenderer.calculateMiddlePoint(model)

  local params = {
    xRotation = viewParams.xRotation, yRotation = viewParams.yRotation, zRotation = viewParams.zRotation,
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
    middlePoint = mp,
    shadingMode = viewParams.shadingMode or "Stack",
    fxStack = viewParams.fxStack,
    metrics = {}
  }

  local t0 = nowMs()
  local image = previewRenderer.renderVoxelModel(model, params)
  local t1 = nowMs()
  params.metrics.renderTime = params.metrics.renderTime or (t1 - t0)
  params.metrics.t_total_ms = params.metrics.t_total_ms or params.metrics.renderTime
  _lastMetrics = params.metrics
  _lastRenderAt = t1

  if dialogueManager and dialogueManager.controlsDialog then
    pcall(function()
      dialogueManager.controlsDialog:modify{ id="scaleLabel", text="Scale: " .. string.format("%.0f%%", (viewParams.scaleLevel or 1)*100) }
      if _lastMetrics and _lastMetrics.t_total_ms then
        dialogueManager.controlsDialog:modify{ id="metricsLabel", text = string.format("Render: %.1f ms", _lastMetrics.t_total_ms) }
      end
    end)
  end

  return image, model, mp
end

function viewerCore.updatePreviewCanvas(dlg, viewParams)
  local img = viewerCore.renderPreview(viewParams)
  if dlg and img then pcall(function() dlg:repaint() end) end
  return img
end

function viewerCore.getLastMetrics()
  return _lastMetrics
end

-- Default throttle similar to original tuning
viewerCore.setAdaptiveThrottle{ multiplier = 2.5, minMs = 30, maxMs = 5000 }

return viewerCore