-- core/state.lua
-- Small helpers to initialize and mutate shared view state

local math_utils = require("utils.math_utils")

local M = {}

function M.default()
  return {
    xRotation = 315, yRotation = 324, zRotation = 29,
    rotationMatrix = math_utils.createRotationMatrix(315,324,29),
    scaleLevel = 1.0, shadingMode = "Stack", fxStack = nil,
    lighting = nil, orthogonalView = false, perspectiveScaleRef = "middle",
    canvasSize = 200, fovDegrees = 45
  }
end

function M.updateRotation(vp, x, y, z)
  if x then vp.xRotation = x end
  if y then vp.yRotation = y end
  if z then vp.zRotation = z end
  vp.rotationMatrix = math_utils.createRotationMatrix(vp.xRotation, vp.yRotation, vp.zRotation)
  return vp
end

function M.setScale(vp, s)
  vp.scaleLevel = math.max(0.05, math.min(8.0, s or 1.0))
  return vp
end

return M