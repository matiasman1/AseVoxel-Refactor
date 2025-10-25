-- Camera parameters and derived view settings
local mathUtils = require("utils.mathUtils")

local camera = {}

function camera.compute(params)
  local fov = params.fovDegrees or 45
  local ortho = params.orthogonal or false
  local x = params.x or params.xRotation or 0
  local y = params.y or params.yRotation or 0
  local z = params.z or params.zRotation or 0
  local M = mathUtils.createRotationMatrix(x, y, z)
  return {
    fov = fov,
    orthogonal = ortho,
    rotationMatrix = M,
    viewDir = { x=0, y=0, z=1 }
  }
end

return camera