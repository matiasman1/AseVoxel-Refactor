-- Minimal math utilities used across modules; Phase 2: port full set
local mathUtils = {}

local function deg2rad(d) return (d or 0) * math.pi / 180 end

function mathUtils.identity()
  return {
    1,0,0,
    0,1,0,
    0,0,1
  }
end

function mathUtils.createRotationMatrix(xDeg, yDeg, zDeg)
  local x = deg2rad(xDeg or 0)
  local y = deg2rad(yDeg or 0)
  local z = deg2rad(zDeg or 0)

  local cx, sx = math.cos(x), math.sin(x)
  local cy, sy = math.cos(y), math.sin(y)
  local cz, sz = math.cos(z), math.sin(z)

  -- Rz * Ry * Rx
  local m00 = cz*cy
  local m01 = cz*sy*sx - sz*cx
  local m02 = cz*sy*cx + sz*sx

  local m10 = sz*cy
  local m11 = sz*sy*sx + cz*cx
  local m12 = sz*sy*cx - cz*sx

  local m20 = -sy
  local m21 = cy*sx
  local m22 = cy*cx

  return {
    m00, m01, m02,
    m10, m11, m12,
    m20, m21, m22
  }
end

return mathUtils