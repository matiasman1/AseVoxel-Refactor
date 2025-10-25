-- render/preview/shading.lua
-- Build visible faces and shade them (Basic/Stack/Dynamic)
local fxStack = require("fxStack")
local mathUtils = require("mathUtils")

local shading = {}

local function nkey(x,y,z) return string.format("%d:%d:%d", x,y,z) end
local OFFS = {
  {1,0,0,"right"}, {-1,0,0,"left"},
  {0,1,0,"bottom"}, {0,-1,0,"top"},
  {0,0,1,"back"}, {0,0,-1,"front"}
}

local function visibleFaces(model)
  local ns = {}
  for _,v in ipairs(model) do ns[nkey(v.x,v.y,v.z)] = true end
  local faces = {}
  for _,v in ipairs(model) do
    for _,o in ipairs(OFFS) do
      local tx,ty,tz,fn = v.x+o[1], v.y+o[2], v.z+o[3], o[4]
      if not ns[nkey(tx,ty,tz)] then
        faces[#faces+1] = { voxel=v, face=fn, color=v.color }
      end
    end
  end
  return faces
end

local function basicShade(color, face, params, cam)
  -- Simple brightness based on color luminance and face bias
  local c = color or { r=255,g=255,b=255,a=255 }
  local lum = ((c.r*0.299 + c.g*0.587 + c.b*0.114) / 255)
  if face == "top" then lum = math.min(1.0, lum * 1.05) end
  return {
    r = math.floor(c.r * lum),
    g = math.floor(c.g * lum),
    b = math.floor(c.b * lum),
    a = c.a or 255
  }
end

function shading.apply(model, params, cam)
  local faces = visibleFaces(model)

  -- Ensure rotation matrix and viewDir are present for fxStack parity
  params.rotationMatrix = params.rotationMatrix or cam.rotationMatrix
  params.viewDir = params.viewDir or cam.viewDir
  params._rotationMatrixForFX = params._rotationMatrixForFX or params.rotationMatrix

  local out = {}
  for _,e in ipairs(faces) do
    local shaded = e.color
    if params.shadingMode == "Stack" and params.fxStack then
      shaded = fxStack.shadeFace(params, e.face, e.color)
    else
      shaded = basicShade(e.color, e.face, params, cam)
    end
    out[#out+1] = { x=e.voxel.x, y=e.voxel.y, z=e.voxel.z, face=e.face, color=shaded }
  end
  return out
end

return shading