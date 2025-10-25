-- render/preview/camera.lua
local mathUtils = require("utils.mathUtils")

local camera = {}

-- Compute camera parameters with tuning analogous to original previewRenderer
function camera.compute(params)
  local fovDeg = params.fovDegrees or 45
  local orthogonal = params.orthogonal or false
  local x = params.x or params.xRotation or 0
  local y = params.y or params.yRotation or 0
  local z = params.z or params.zRotation or 0

  local M = mathUtils.createRotationMatrix(x, y, z)

  local canvasSize = params.canvasSize or 200
  local fov = math.max(5, math.min(75, fovDeg))
  local focalLength = (canvasSize/2) / math.tan(math.rad(fov)/2)

  return {
    fov = fov,
    orthogonal = orthogonal,
    rotationMatrix = M,
    focalLength = focalLength,
    canvasSize = canvasSize,
    viewDir = { 0, 0, 1 }
  }
end

return camera