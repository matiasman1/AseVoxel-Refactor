-- render/preview_utils.lua
-- Enhanced version of the preview utilities

local rendererFactory = require("render.renderer_factory")
local mathUtils = require("utils.math_utils")
local debug = require("core.debug")

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
  if not sprite then 
    debug.log("No active sprite")
    return nil 
  end
  
  -- Get voxel model from sprite
  local modelExtractor = require("render.local.model_extraction")
  local vox = modelExtractor.generateVoxelModel(sprite)
  
  if #vox == 0 then 
    debug.log("No voxels in model")
    return nil 
  end
  
  -- Apply layer scrolling if enabled
  if viewParams.layerScrollMode and type(viewParams.layerScrollMin) == "number" and type(viewParams.layerScrollMax) == "number" then
    local filtered = {}
    for _, v in ipairs(vox) do
      if v.z >= viewParams.layerScrollMin and v.z <= viewParams.layerScrollMax then
        table.insert(filtered, v)
      end
    end
    vox = filtered
  end
  
  local mp = modelExtractor.calculateMiddlePoint(vox)
  
  -- Configure rendering parameters
  local rp = {
    x = viewParams.xRotation, 
    y = viewParams.yRotation, 
    z = viewParams.zRotation,
    fovDegrees = toFov(viewParams),
    orthogonal = viewParams.orthogonalView,
    perspectiveScaleRef = viewParams.perspectiveScaleRef or "middle",
    scaleLevel = viewParams.scaleLevel,
    rotationMatrix = viewParams.rotationMatrix,
    fxStack = viewParams.fxStack,
    shadingMode = viewParams.shadingMode or "Stack",
    lighting = viewParams.lighting,
    useMesh = viewParams.useMesh,
    useNative = viewParams.useNative,
    enableOutline = viewParams.enableOutline,
    outlineSettings = viewParams.outlineSettings,
    middlePoint = mp,
    sprite = sprite,
    width = viewParams.width or viewParams.canvasSize or 300,
    height = viewParams.height or viewParams.canvasSize or 300
  }
  
  -- Render using appropriate renderer based on mode
  local startTime = nowMs()
  local img = rendererFactory.renderVoxelModel(vox, rp)
  local endTime = nowMs()
  
  debug.log(string.format("Render time: %.2fms", endTime - startTime))
  
  return { 
    image = img, 
    model = vox, 
    dimensions = mp,
    renderTimeMs = endTime - startTime
  }
end

local function schedule(dlg, viewParams, source, cb)
  if _sched.rendering then 
    _sched.pending = { dlg=dlg, vp=viewParams, src=source, cb=cb }
    return 
  end
  
  _sched.rendering = true
  local t0 = nowMs()
  
  -- Perform the render
  local ok, res = pcall(renderOnce, viewParams)
  
  -- Call the callback with the result
  if cb then pcall(function() cb(ok and res or nil) end) end
  
  _sched.rendering = false
  
  -- Handle pending renders
  if _sched.pending then
    local nextReq = _sched.pending
    _sched.pending = nil
    schedule(nextReq.dlg, nextReq.vp, nextReq.src, nextReq.cb)
  end
  
  -- Adjust throttling based on render time
  local dt = nowMs() - t0
  _sched.intervalMs = math.max(30, math.min(500, math.floor(dt * 3)))
end

function M.openPreview(state, cb)
  schedule(nil, state, "init", cb)
end

function M.queuePreview(state, source, cb)
  local now = nowMs()
  
  -- Throttle mouse move events
  if source == "mouseMove" and (now - _sched.lastMouseMs) < _sched.intervalMs then
    _sched.pending = { dlg=nil, vp=state, src=source, cb=cb }
    return
  end
  
  -- Throttle control change events
  if source == "controls" and (now - _sched.lastCtrlMs) < _sched.intervalMs then
    _sched.pending = { dlg=nil, vp=state, src=source, cb=cb }
    return
  end
  
  if source == "mouseMove" then _sched.lastMouseMs = now end
  if source == "controls" then _sched.lastCtrlMs = now end
  
  schedule(nil, state, source, cb)
end

return M