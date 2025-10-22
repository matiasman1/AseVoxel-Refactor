-- core/viewer_core.lua
-- Thin adapter over existing viewerCore.lua logic, now modular and small entrypoints

local preview_utils = require("render.preview_utils")
local help_dialog = require("dialog.help_dialog")
local controls_dialog = require("dialog.controls_dialog")
local model_viewer = require("dialog.model_viewer")
local preview_window = require("dialog.preview_window")

local M = {}

local function showPreview(state)
  preview_utils.openPreview(state, function(result)
    -- optional callback (metrics, image)
  end)
end

function M.openMain(state)
  -- Open separate preview window like AseVoxel
  preview_window.open(state)
  -- Keep main viewer (actions hub) to mimic AseVoxel's main dialog
  model_viewer.open(state)
  controls_dialog.open(state, {
    onChange = function(vp)
      preview_utils.queuePreview(vp, "controls")
    end,
    onHelp = function() help_dialog.open() end
  })
end

return M