-- Camera, rotation, projection utilities

local math_utils = require("utils.math_utils")

local M = {}

function M.rotationMatrix(params)
  if params.rotationMatrix then return params.rotationMatrix end
  local x = params.x or params.xRotation or 0
  local y = params.y or params.yRotation or 0
  local z = params.z or params.zRotation or 0
  return math_utils.createRotationMatrix(x, y, z)
end

function M.toFov(params)
  if params.fovDegrees then return params.fovDegrees end
  local dp = params.depthPerspective
  return dp and (5 + (75-5)*(dp/100)) or 45
end

function M.focalLength(height, fovDeg)
  local f = math.rad(math.max(1, math.min(179, fovDeg)))
  return (height/2) / math.tan(f/2)
end

local function mul3(m, v)
  return {
    m[1][1]*v[1]+m[1][2]*v[2]+m[1][3]*v[3],
    m[2][1]*v[1]+m[2][2]*v[2]+m[2][3]*v[3],
    m[3][1]*v[1]+m[3][2]*v[2]+m[3][3]*v[3],
  }
end

function M.rotatePoint(matrix, origin, p)
  local x,y,z = p[1]-origin.x, p[2]-origin.y, p[3]-origin.z
  local r = mul3(matrix, {x,y,z})
  return { r[1]+origin.x, r[2]+origin.y, r[3]+origin.z }
end

function M.project(camera, p)
  if camera.orthogonal then
    return p[1]*camera.scale + camera.cx, p[2]*camera.scale + camera.cy, p[3]
  end
  local dz = (p[3] - camera.posZ)
  local k = camera.focal / math.max(1e-3, -dz)
  return p[1]*k + camera.cx, p[2]*k + camera.cy, p[3]
end

function M.build(bounds, mp, params, width, height, scaleLevel)
  local fov = M.toFov(params)
  local focal = M.focalLength(height, fov)
  local ortho = params.orthogonal or params.orthogonalView
  local diag = math.sqrt(mp.sizeX^2 + mp.sizeY^2 + mp.sizeZ^2)
  local dist = ortho and 0 or (diag * 2.2)
  return {
    focal=focal, orthogonal=ortho, posZ = mp.z + dist,
    cx=math.floor(width/2), cy=math.floor(height/2),
    scale=scaleLevel or 1.0
  }
end

return M