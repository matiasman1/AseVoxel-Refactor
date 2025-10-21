-- dialog/utils/animation_logic.lua
-- Pure helpers for animation dialog

local math_utils = require("utils.math_utils")
local rotation = require("core.rotation")
local preview_utils = require("render.preview_utils")
local previewRenderer = require("render.previewRenderer")
local debug = require("core.debug")

local M = {}

function M.frameDurationMs(steps)
  steps = tonumber(steps) or 36
  return math.ceil(1440 / steps)
end

function M.degreesPerStep(total, steps)
  return (tonumber(total) or 360) / (tonumber(steps) or 36)
end

function M.buildFrameMatrix(baseMatrix, axis, angle)
  debug.log(string.format("animation_logic.buildFrameMatrix axis=%s angle=%s", tostring(axis), tostring(angle)))
  if axis=="X" then
    return rotation.applyAbsoluteRotation(baseMatrix, angle, 0, 0)
  elseif axis=="Y" then
    return rotation.applyAbsoluteRotation(baseMatrix, 0, angle, 0)
  elseif axis=="Z" then
    return rotation.applyAbsoluteRotation(baseMatrix, 0, 0, angle)
  elseif axis=="Pitch" then
    return math_utils.applyRelativeRotation(baseMatrix, angle, 0, 0)
  elseif axis=="Yaw" then
    return math_utils.applyRelativeRotation(baseMatrix, 0, angle, 0)
  elseif axis=="Roll" then
    return math_utils.applyRelativeRotation(baseMatrix, 0, 0, angle)
  end
  return baseMatrix
end

return M