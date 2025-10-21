-- Simple dynamic lighting helpers

local C = require("render.local.constants")

local M = {}

local function norm3(v)
  local m = math.sqrt(v[1]^2+v[2]^2+v[3]^2)
  if m < 1e-6 then return {0,0,1} end
  return {v[1]/m, v[2]/m, v[3]/m}
end

function M.lightDir(lighting)
  if not lighting then return {0,0,1} end
  local yaw = math.rad(lighting.yaw or 0)
  local pitch = math.rad(lighting.pitch or 0)
  local x =  math.cos(pitch)*math.sin(yaw)
  local y = -math.sin(pitch)
  local z =  math.cos(pitch)*math.cos(yaw)
  return norm3({x,y,z})
end

function M.faceBrightness(faceName, rotM, lighting)
  local n = C.FACE_NORMALS[faceName] or {0,0,1}
  local nx = rotM[1][1]*n[1]+rotM[1][2]*n[2]+rotM[1][3]*n[3]
  local ny = rotM[2][1]*n[1]+rotM[2][2]*n[2]+rotM[2][3]*n[3]
  local nz = rotM[3][1]*n[1]+rotM[3][2]*n[2]+rotM[3][3]*n[3]
  local L = M.lightDir(lighting)
  local dot = math.max(0, nx*L[1]+ny*L[2]+nz*L[3])
  local amb = (lighting and lighting.ambient or 30)/100
  local dif = (lighting and lighting.diffuse or 60)/100
  return math.max(amb, amb + dif*dot)
end

function M.tintColor(col, k, color)
  local lr = (color and (color.red or color.r)) or 255
  local lg = (color and (color.green or color.g)) or 255
  local lb = (color and (color.blue or color.b)) or 255
  return {
    r = C.clampByte(col.r * (0.2 + 0.8*k) * (lr/255)),
    g = C.clampByte(col.g * (0.2 + 0.8*k) * (lg/255)),
    b = C.clampByte(col.b * (0.2 + 0.8*k) * (lb/255)),
    a = col.a or 255
  }
end

return M