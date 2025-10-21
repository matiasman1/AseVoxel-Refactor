-- core/rotation.lua
-- Moved from rotation.lua, trimmed and kept modular

local math_utils = require("utils.math_utils")
local nativeBridge_ok, nativeBridge = pcall(require, "nativeBridge")

local M = {}

function M.wrapAngle(angle)
  local w = angle % 360
  return (w > 180) and (w - 360) or w
end

function M.applyAbsoluteRotation(currentMatrix, dx, dy, dz)
  local delta = math_utils.createRotationMatrix(dx or 0, dy or 0, dz or 0)
  return math_utils.multiplyMatrices(currentMatrix, delta)
end

function M.applyRelativeRotation(currentMatrix, pitch, yaw, roll)
  return math_utils.applyRelativeRotation(currentMatrix, pitch or 0, yaw or 0, roll or 0)
end

function M.transformVoxel(voxel, params)
  if nativeBridge_ok and nativeBridge and nativeBridge.isAvailable and nativeBridge.isAvailable()
     and nativeBridge.transformVoxel then
    local transformed = nativeBridge.transformVoxel(voxel, params)
    if transformed and transformed.x then return transformed end
  end
  local t = {
    x = voxel.x - params.middlePoint.x,
    y = voxel.y - params.middlePoint.y,
    z = voxel.z - params.middlePoint.z,
    color = voxel.color
  }
  local xr,yr,zr = math.rad(params.xRotation), math.rad(params.yRotation), math.rad(params.zRotation)
  local cx,sx = math.cos(xr), math.sin(xr)
  local cy,sy = math.cos(yr), math.sin(yr)
  local cz,sz = math.cos(zr), math.sin(zr)
  local x,y,z = t.x, t.y, t.z
  local y2 = y*cx - z*sx; local z2 = y*sx + z*cx; y,z = y2,z2
  local x2 = x*cy + z*sy; local z3 = -x*sy + z*cy; x,z = x2,z3
  local x3 = x*cz - y*sz; local y3 = x*sz + y*cz; x,y = x3,y3
  t.x = x + params.middlePoint.x
  t.y = y + params.middlePoint.y
  t.z = z + params.middlePoint.z
  t.normal = { x=0, y=0, z=0 }
  return t
end

function M.optimizeVoxelModel(voxels)
  local map, out = {}, {}
  for _,v in ipairs(voxels) do map[v.x..","..v.y..","..v.z] = true end
  for _,v in ipairs(voxels) do
    local h = {
      front = map[v.x..","..v.y..","..(v.z+1)] or false,
      back  = map[v.x..","..v.y..","..(v.z-1)] or false,
      right = map[(v.x+1)..","..v.y..","..v.z] or false,
      left  = map[(v.x-1)..","..v.y..","..v.z] or false,
      top   = map[v.x..","..(v.y+1)..","..v.z] or false,
      bottom= map[v.x..","..(v.y-1)..","..v.z] or false
    }
    out[#out+1] = { voxel=v, hiddenFaces=h }
  end
  return out
end

return M