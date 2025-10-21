-- core/controller.lua
-- Unifies responsibilities previously split across dialogueManager/modelViewer

local viewer_core = require("core.viewer_core")
local sprite_watcher = require("core.sprite_watcher")

local M = {}

local function newState()
  return {
    rotationMatrix = nil,
    scaleLevel = 1.0,
    shadingMode = "Stack",
    fxStack = nil,
    lighting = nil,
    orthogonalView = false,
    perspectiveScaleRef = "middle",
  }
end

local function ensureWatchers(state)
  sprite_watcher.start(state)
end

function M.safeUpdate(viewParams, updateFn)
  if not viewParams or type(updateFn) ~= "function" then return end
  local ok, err = pcall(function() updateFn(viewParams) end)
  if not ok then print("[safeUpdate] " .. tostring(err)) end
end

function M.openViewer()
  local state = newState()
  ensureWatchers(state)
  viewer_core.openMain(state) -- thin entrypoint that shows main preview dialog
end

return M