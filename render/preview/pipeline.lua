-- Pure-Lua render pipeline (camera, shading, raster, fx)
-- Phase 1: stub minimal pipeline; Phase 2: port full logic from original
local cameraMod = require("render.preview.camera")
local shadingMod = require("render.preview.shading")
local rasterMod = require("render.preview.raster")
local fxMod = require("render.preview.fx")

local pipeline = {}

function pipeline.render(model, params, metrics, deps)
  metrics = metrics or {}
  local t0 = os.clock() * 1000

  -- Compute camera
  local cam = cameraMod.compute(params)

  -- Shade voxels (placeholder)
  local shaded = shadingMod.apply(model, params, cam)

  -- Rasterize to image (placeholder)
  local image = rasterMod.draw(shaded, params, cam)

  -- FX
  image = fxMod.apply(image, params)

  -- Downsample / finalize
  if deps and deps.downsample then
    image = deps.downsample(image, params, metrics)
  end

  metrics.t_total_ms = (os.clock() * 1000) - t0
  return image
end

return pipeline