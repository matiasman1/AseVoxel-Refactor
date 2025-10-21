-- utils/math_utils.lua (moved from mathUtils.lua, unchanged function names)
local M = {}

function M.atan2(y, x)
  if math.atan2 then return math.atan2(y, x) end
  if x > 0 then return math.atan(y / x)
  elseif x < 0 and y >= 0 then return math.atan(y / x) + math.pi
  elseif x < 0 and y < 0 then return math.atan(y / x) - math.pi
  elseif x == 0 and y > 0 then return math.pi / 2
  elseif x == 0 and y < 0 then return -math.pi / 2
  else return 0 end
end

function M.identity()
  return { {1,0,0}, {0,1,0}, {0,0,1} }
end

function M.multiplyMatrices(a, b)
  local r = { {0,0,0}, {0,0,0}, {0,0,0} }
  for i=1,3 do for j=1,3 do
    local s=0; for k=1,3 do s=s+a[i][k]*b[k][j] end
    r[i][j]=s
  end end
  return r
end

function M.createRotationMatrix(xDeg, yDeg, zDeg)
  xDeg=(xDeg%360+360)%360; yDeg=(yDeg%360+360)%360; zDeg=(zDeg%360+360)%360
  local xr,yr,zr = math.rad(xDeg),math.rad(yDeg),math.rad(zDeg)
  local cx,sx = math.cos(xr),math.sin(xr)
  local cy,sy = math.cos(yr),math.sin(yr)
  local cz,sz = math.cos(zr),math.sin(zr)
  local X = { {1,0,0},{0,cx,-sx},{0,sx,cx} }
  local Y = { {cy,0,sy},{0,1,0},{-sy,0,cy} }
  local Z = { {cz,-sz,0},{sz,cz,0},{0,0,1} }
  return M.multiplyMatrices(Z, M.multiplyMatrices(Y, X))
end

function M.matrixToEuler(m)
  local sy = math.sqrt(m[1][1]^2 + m[2][1]^2)
  local singular = sy < 1e-6
  local x,y,z
  if not singular then
    x = M.atan2(m[3][2], m[3][3])
    y = M.atan2(-m[3][1], sy)
    z = M.atan2(m[2][1], m[1][1])
  else
    x = M.atan2(-m[2][3], m[2][2]); y = M.atan2(-m[3][1], sy); z = 0
  end
  x=(math.deg(x)%360+360)%360; y=(math.deg(y)%360+360)%360; z=(math.deg(z)%360+360)%360
  return {x=x,y=y,z=z}
end

function M.createRelativeRotationMatrix(pitchDelta,yawDelta,rollDelta)
  local pr,yr,rr = math.rad(pitchDelta),math.rad(yawDelta),math.rad(rollDelta)
  local P={{1,0,0},{0,math.cos(pr),-math.sin(pr)},{0,math.sin(pr),math.cos(pr)}}
  local Y={{math.cos(yr),0,math.sin(yr)},{0,1,0},{-math.sin(yr),0,math.cos(yr)}}
  local R={{math.cos(rr),-math.sin(rr),0},{math.sin(rr),math.cos(rr),0},{0,0,1}}
  return M.multiplyMatrices(R, M.multiplyMatrices(P, Y))
end

function M.applyRelativeRotation(currentMatrix, pitchDelta, yawDelta, rollDelta)
  local C = M.createRelativeRotationMatrix(pitchDelta, yawDelta, rollDelta)
  return M.multiplyMatrices(C, currentMatrix)
end

function M.setAxisRotation(currentMatrix, axis, newAngleDeg)
  local e = M.matrixToEuler(currentMatrix)
  if axis=="x" then e.x=newAngleDeg elseif axis=="y" then e.y=newAngleDeg else e.z=newAngleDeg end
  return M.createRotationMatrix(e.x,e.y,e.z)
end

function M.normalizeAngle(a)
  local n=(a%360+360)%360
  if math.abs(n-360)<0.001 then n=0 end
  return n
end

function M.isOrthogonal(matrix)
  local m=matrix
  local det = m[1][1]*(m[2][2]*m[3][3]-m[2][3]*m[3][2])
            - m[1][2]*(m[2][1]*m[3][3]-m[2][3]*m[3][1])
            + m[1][3]*(m[2][1]*m[3][2]-m[2][2]*m[3][1])
  return math.abs(det-1.0)<0.001
end

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
  local L=math.sqrt(ax*ax+ay*ay+az*az); if L<1e-6 then return M.identity() end
  ax,ay,az = ax/L, ay/L, az/L
  return {
    {t*ax*ax + c,      t*ax*ay - s*az, t*ax*az + s*ay},
    {t*ax*ay + s*az,   t*ay*ay + c,    t*ay*az - s*ax},
    {t*ax*az - s*ay,   t*ay*az + s*ax, t*az*az + c}
  }
end

function M.transposeMatrix(m)
  return { {m[1][1],m[2][1],m[3][1]}, {m[1][2],m[2][2],m[3][2]}, {m[1][3],m[2][3],m[3][3]} }
end

return M