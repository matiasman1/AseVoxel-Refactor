-- mathUtils.lua: matrix and vector helpers used across modules
local mathUtils = {}

local function deg2rad(d) return (d or 0) * math.pi / 180 end

function mathUtils.identity()
  return { 1,0,0, 0,1,0, 0,0,1 }
end

-- Rotation matrix from Euler degrees (Rz * Ry * Rx)
function mathUtils.createRotationMatrix(xDeg, yDeg, zDeg)
  local x = deg2rad(xDeg or 0)
  local y = deg2rad(yDeg or 0)
  local z = deg2rad(zDeg or 0)
  local cx,sx = math.cos(x), math.sin(x)
  local cy,sy = math.cos(y), math.sin(y)
  local cz,sz = math.cos(z), math.sin(z)

  local m00 = cz*cy
  local m01 = cz*sy*sx - sz*cx
  local m02 = cz*sy*cx + sz*sx

  local m10 = sz*cy
  local m11 = sz*sy*sx + cz*cx
  local m12 = sz*sy*cx - cz*sx

  local m20 = -sy
  local m21 = cy*sx
  local m22 = cy*cx

  return { m00,m01,m02, m10,m11,m12, m20,m21,m22 }
end

function mathUtils.applyRotation(M, p)
  if not M or not p then return { x=p.x, y=p.y, z=p.z } end
  return {
    x = M[1]*p.x + M[2]*p.y + M[3]*p.z,
    y = M[4]*p.x + M[5]*p.y + M[6]*p.z,
    z = M[7]*p.x + M[8]*p.y + M[9]*p.z
  }
end

function mathUtils.vecAdd(a,b) return { x=a.x+b.x, y=a.y+b.y, z=a.z+b.z } end
function mathUtils.vecSub(a,b) return { x=a.x-b.x, y=a.y-b.y, z=a.z-b.z } end
function mathUtils.dot(a,b) return a.x*b.x + a.y*b.y + a.z*b.z end
function mathUtils.len(a) return math.sqrt(a.x*a.x + a.y*a.y + a.z*a.z) end

return mathUtils