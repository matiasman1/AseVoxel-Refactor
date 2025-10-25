-- Facade for preview rendering (public API preserved)
local RemoteRenderer = require("render.remoteRenderer")
local modelMod = require("render.preview.model")
local pipelineMod = require("render.preview.pipeline")
local downsampleMod = require("render.preview.downsample")

local previewRenderer = {}

function previewRenderer.generateVoxelModel(sprite)
  return modelMod.generateVoxelModel(sprite)
end

function previewRenderer.calculateMiddlePoint(model)
  return modelMod.calculateMiddlePoint(model)
end

function previewRenderer.renderVoxelModel(model, params)
  params = params or {}
  params.metrics = params.metrics or {}

  -- Try native backend first (fast path), then fallback to Lua pipeline
  local nativeImage, err = RemoteRenderer.nativeRender(model, params, params.metrics)
  if nativeImage then return nativeImage end

  -- Pure-Lua pipeline
  return pipelineMod.render(model, params, params.metrics, {
    downsample = downsampleMod.downsample
  })
end

return previewRenderer