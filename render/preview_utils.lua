-- render/preview_utils.lua
-- Small, composable helpers around preview rendering and queueing

local previewRenderer = require("previewRenderer")
local math_utils = require("utils.math_utils")

local M = {}
local _sched = {
  rendering = false,
  lastMouseMs = 0,
  lastCtrlMs = 0,
  intervalMs = 100,
  pending = nil
}

local function nowMs() return os.clock() * 1000 end

local function toFov(params)
  if params.fovDegrees then return params.fovDegrees end
  if params.depthPerspective then
    return 5 + (75-5)*((params.depthPerspective or 50)/100)
  end
  return 45
end

local function renderOnce(viewParams)
  local sprite = app.activeSprite
  if not sprite then return nil end
  local vox = previewRenderer.generateVoxelModel(sprite)
  if #vox == 0 then return nil end
  local mp = previewRenderer.calculateMiddlePoint(vox)
  local rp = {
    x = viewParams.xRotation, y = viewParams.yRotation, z = viewParams.zRotation,
    fovDegrees = toFov(viewParams),
    orthogonal = viewParams.orthogonalView,
    perspectiveScaleRef = viewParams.perspectiveScaleRef or "middle",
    scaleLevel = viewParams.scaleLevel,
    rotationMatrix = viewParams.rotationMatrix,
    fxStack = viewParams.fxStack,
    shadingMode = viewParams.shadingMode or "Stack",
    lighting = viewParams.lighting,
    middlePoint = mp,
    sprite = sprite
  }
  local img = previewRenderer.renderVoxelModel(vox, rp)
  return { image = img, model = vox, dimensions = mp }
end

local function schedule(dlg, viewParams, source, cb)
  if _sched.rendering then _sched.pending = { dlg=dlg, vp=viewParams, src=source, cb=cb }; return end
  _sched.rendering = true
  local t0 = nowMs()
  local ok, res = pcall(renderOnce, viewParams)
  if cb then pcall(function() cb(ok and res or nil) end) end
  _sched.rendering = false
  if _sched.pending then
    local nextReq = _sched.pending
    _sched.pending = nil
    schedule(nextReq.dlg, nextReq.vp, nextReq.src, nextReq.cb)
  end
  local dt = nowMs() - t0
  _sched.intervalMs = math.max(30, math.min(500, math.floor(dt * 3)))
end

function M.openPreview(state, cb)
  schedule(nil, state, "init", cb)
end

function M.queuePreview(state, source)
  local now = nowMs()
  if source == "mouseMove" and (now - _sched.lastMouseMs) < _sched.intervalMs then
    _sched.pending = { dlg=nil, vp=state, src=source, cb=nil }
    return
  end
  if source == "controls" and (now - _sched.lastCtrlMs) < _sched.intervalMs then
    _sched.pending = { dlg=nil, vp=state, src=source, cb=nil }
    return
  end
  if source == "mouseMove" then _sched.lastMouseMs = now end
  if source == "controls" then _sched.lastCtrlMs = now end
  schedule(nil, state, source, nil)
end

return M