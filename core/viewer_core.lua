-- core/viewer_core.lua
-- Thin adapter over existing viewerCore.lua logic, now modular and small entrypoints

local preview_utils = require("render.preview_utils")
local help_dialog = require("dialog.help_dialog")
local controls_dialog = require("dialog.controls_dialog")
local model_viewer = require("dialog.model_viewer")

local M = {}

local function showPreview(state)
  preview_utils.openPreview(state, function(result)
    -- optional callback (metrics, image)
  end)
end

function M.openMain(state)
  model_viewer.open(state)
  model_viewer.requestRender(state)
  controls_dialog.open(state, {
    onChange = function(vp) model_viewer.requestRender(vp) end,
    onHelp = function() help_dialog.open() end
  })
end

return M