-- Facade for preview rendering (public API preserved)
-- Internals are delegated to submodules under render/preview/*
local mathUtils = require("utils.mathUtils")
local rotation = require("utils.rotation")
local RemoteRenderer = require("render.remoteRenderer")

-- Submodules (to be populated with original logic over time)
local modelMod = require("render.preview.model")
local pipelineMod = require("render.preview.pipeline")
local downsampleMod = require("render.preview.downsample")

local previewRenderer = {}

-- Public API: identical names/semantics to original
function previewRenderer.generateVoxelModel(sprite)
  return modelMod.generateVoxelModel(sprite)
end

function previewRenderer.calculateMiddlePoint(model)
  return modelMod.calculateMiddlePoint(model)
end

function previewRenderer.renderVoxelModel(model, params)
  params = params or {}
  -- attempt native path first
  local image, err = RemoteRenderer.nativeRender(model, params, params.metrics)
  if image then return image end

  -- pure-Lua pipeline path
  return pipelineMod.render(model, params, params.metrics, {
    downsample = downsampleMod.downsample
  })
end

return previewRenderer