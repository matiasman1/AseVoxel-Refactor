-- render/preview/pipeline.lua
local cameraMod = require("camera")
local shadingMod = require("shading")
local rasterMod = require("raster")
local downsample = require("downsample")

local pipeline = {}

function pipeline.render(model, params, metrics, deps)
  metrics = metrics or {}
  local t0 = os.clock() * 1000

  local cam = cameraMod.compute(params)
  metrics.t_camera_ms = os.clock()*1000 - t0

  local shaded = shadingMod.apply(model, params, cam)
  metrics.t_shade_ms = os.clock()*1000 - t0 - metrics.t_camera_ms

  local img = rasterMod.draw(shaded, params, cam)
  metrics.t_raster_ms = os.clock()*1000 - t0 - (metrics.t_camera_ms + metrics.t_shade_ms)

  if deps and deps.downsample then img = deps.downsample(img, params, metrics) end
  metrics.t_total_ms = os.clock()*1000 - t0

  return img
end

return pipeline