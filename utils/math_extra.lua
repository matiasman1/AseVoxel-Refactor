-- utils/math_extra.lua
-- Auxiliary math helpers split to keep math_utils under 12 functions

local M = {}

function M.mouseToTrackball(sx,sy, ex,ey, w,h)
  local function project(x, y)
    local nx = 2.0*x/w - 1.0
    local ny = 1.0 - 2.0*y/h
    local len = math.sqrt(nx*nx + ny*ny)
    local nz = (len < 0.7071) and math.sqrt(1.0 - len*len) or (0.5 / len)
    return nx,ny,nz
  end
  local p1x,p1y,p1z = project(sx,sy)
  local p2x,p2y,p2z = project(ex,ey)
  local ax = p1y*p2z - p1z*p2y
  local ay = p1z*p2x - p1x*p2z
  local az = p1x*p2y - p1y*p2x
  local dot = p1x*p2x + p1y*p2y + p1z*p2z
  local angle = math.acos(math.max(-1, math.min(1, dot)))
  return ax,ay,az, math.deg(angle)
end

function M.createAxisAngleMatrix(ax,ay,az, deg)
  local r=math.rad(deg); local c=math.cos(r); local s=math.sin(r); local t=1-c
  local L=math.sqrt(ax*ax+ay*ay+az*az); if L<1e-6 then
    return { {1,0,0},{0,1,0},{0,0,1} }
  end
  ax,ay,az = ax/L, ay/L, az/L
  return {
    {t*ax*ax + c,      t*ax*ay - s*az, t*ax*az + s*ay},
    {t*ax*ay + s*az,   t*ay*ay + c,    t*ay*az - s*ax},
    {t*ax*az - s*ay,   t*ay*az + s*ax, t*az*az + c}
  }
end

function M.transpose3(m)
  return { {m[1][1],m[2][1],m[3][1]}, {m[1][2],m[2][2],m[3][2]}, {m[1][3],m[2][3],m[3][3]} }
end

return M