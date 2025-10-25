-- Pure-Lua render pipeline (camera, shading, raster)
local cameraMod = require("render.preview.camera")
local shadingMod = require("render.preview.shading")
local rasterMod = require("render.preview.raster")
local mathUtils = require("utils.mathUtils")

local pipeline = {}

-- Render pipeline: model -> shadedModel -> image
-- params.metrics is a table we will populate with timing metrics
function pipeline.render(model, params, metrics, deps)
  metrics = metrics or {}
  local t0 = os.clock() * 1000

  -- Camera
  local cam = cameraMod.compute(params)

  -- Optionally apply rotation matrix to the model positions here so downstream sees rotated coords
  local M = cam.rotationMatrix
  for _, v in ipairs(model) do
    local p = { x = v.x, y = v.y, z = v.z }
    local rp = mathUtils.applyRotation(M, p)
    v._rx = rp.x; v._ry = rp.y; v._rz = rp.z
    -- overwrite world coords with rotated for simple raster pipeline
    v.x = v._rx; v.y = v._ry; v.z = v._rz
  end

  -- Shading (simple)
  params.rotationMatrix = M
  local shaded = shadingMod.apply(model, params, cam)

  -- Rasterize
  local image = rasterMod.draw(shaded, params, cam)

  if metrics then metrics.t_render_ms = (os.clock() * 1000) - t0 end
  -- Downsample step (no-op currently)
  if deps and deps.downsample and type(deps.downsample) == "function" then
    image = deps.downsample(image, params, metrics)
  end

  metrics.t_total_ms = (os.clock() * 1000) - t0
  return image
end

return pipeline