-- pipeline.lua: integrate camera -> shading -> raster with metrics
local cameraMod = require("render.preview.camera")
local shadingMod = require("render.preview.shading")
local rasterMod = require("render.preview.raster")

local pipeline = {}

function pipeline.render(model, params, metrics, deps)
  metrics = metrics or {}
  local t0 = os.clock() * 1000

  -- camera
  local cam = cameraMod.compute(params)

  -- shading: create face list and shade
  local shadedFaces = shadingMod.apply(model, params, cam)

  metrics.t_shade_ms = (os.clock() * 1000) - t0

  -- rasterize faces to image
  local img = rasterMod.draw(shadedFaces, params, cam)
  metrics.t_raster_ms = (os.clock() * 1000) - t0 - (metrics.t_shade_ms or 0)

  -- downsample step (deps.downsample) if provided
  if deps and deps.downsample then
    img = deps.downsample(img, params, metrics)
  end

  metrics.t_total_ms = (os.clock() * 1000) - t0
  return img
end

return pipeline