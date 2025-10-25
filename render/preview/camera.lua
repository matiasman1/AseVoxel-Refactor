-- render/preview/camera.lua
-- Parity-tuned camera with calibrated perspective distance and FOV mapping
local mathUtils = require("utils.mathUtils")

local camera = {}

local function computeFocal(canvasSize, fovDeg)
  local fov = math.max(5, math.min(75, fovDeg or 45))
  return (canvasSize/2) / math.tan(math.rad(fov)/2), fov
end

-- Computes camera parameters including tuned perspective distance and reference scaling
function camera.compute(params)
  local canvasSize = params.canvasSize or 200
  local focalLength, fov = computeFocal(canvasSize, params.fovDegrees)
  local orthogonal = params.orthogonal or false

  local x = params.x or params.xRotation or 0
  local y = params.y or params.yRotation or 0
  local z = params.z or params.zRotation or 0
  local M = mathUtils.createRotationMatrix(x, y, z)

  -- Calibrated camera distance like original previewRenderer
  local mp = params.middlePoint or { sizeX = 0, sizeY = 0, sizeZ = 0, x=0,y=0,z=0 }
  local maxDimension = math.max(mp.sizeX or 0, mp.sizeY or 0, mp.sizeZ or 0)
  local cameraDistance = 0
  local cameraPos = { x = mp.x, y = mp.y, z = mp.z }
  if not orthogonal then
    local warpT = (fov - 5) / (75 - 5)
    local amplified = warpT ^ (1/3)
    local BASE_NEAR  = 1.2
    local FAR_EXTRA  = 45.0
    cameraDistance = maxDimension * (BASE_NEAR + (1 - amplified)^2 * FAR_EXTRA)
    cameraPos = { x = mp.x, y = mp.y, z = mp.z + cameraDistance }
  end

  -- Reference for perspective scaling (middle/min/max depth). For now pass-through.
  local perspectiveScaleRef = params.perspectiveScaleRef or "middle"

  -- Normalized view direction
  local viewDir = { x = 0, y = 0, z = 1 }
  local mag = math.sqrt(viewDir.x^2 + viewDir.y^2 + viewDir.z^2)
  if mag > 1e-6 then viewDir = { x = viewDir.x/mag, y = viewDir.y/mag, z = viewDir.z/mag } end

  return {
    fov = fov,
    focalLength = focalLength,
    orthogonal = orthogonal,
    rotationMatrix = M,
    canvasSize = canvasSize,
    cameraPos = cameraPos,
    cameraDistance = cameraDistance,
    perspectiveScaleRef = perspectiveScaleRef,
    viewDir = viewDir
  }
end

return camera