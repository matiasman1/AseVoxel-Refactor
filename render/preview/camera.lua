-- Camera parameters and derived view settings
local mathUtils = require("utils.mathUtils")

local camera = {}

-- Compute camera params from render params
function camera.compute(params)
  local fov = params.fovDegrees or 45
  local ortho = params.orthogonal or false
  local x = params.x or params.xRotation or 0
  local y = params.y or params.yRotation or 0
  local z = params.z or params.zRotation or 0

  local M = mathUtils.createRotationMatrix(x, y, z)

  -- Focal length for simple perspective (pixel units)
  local canvasSize = params.canvasSize or 200
  local fovClamped = math.max(5, math.min(75, fov))
  local focalLength = (canvasSize/2) / math.tan(math.rad(fovClamped)/2)

  return {
    fov = fovClamped,
    orthogonal = ortho,
    rotationMatrix = M,
    focalLength = focalLength,
    canvasSize = canvasSize,
    viewDir = { x = 0, y = 0, z = 1 }
  }
end

return camera