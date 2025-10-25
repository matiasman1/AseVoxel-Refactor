-- render/preview/shading.lua
-- Build visible faces and shade them using fxStack or basic shading.

local fxStack = require("fx.fxStack")
local mathUtils = require("utils.mathUtils")

local shading = {}

local function neighborKey(x,y,z) return string.format("%d:%d:%d", x,y,z) end

local function visibleFacesForVoxel(v, neighborSet)
  local faces = {}
  local offsets = {
    {1,0,0,"right"}, {-1,0,0,"left"},
    {0,1,0,"bottom"}, {0,-1,0,"top"},
    {0,0,1,"back"}, {0,0,-1,"front"}
  }
  for _,off in ipairs(offsets) do
    local tx,ty,tz,fn = v.x + off[1], v.y + off[2], v.z + off[3], off[4]
    if not neighborSet[neighborKey(tx,ty,tz)] then faces[#faces+1] = fn end
  end
  return faces
end

local function buildFaces(model)
  local ns = {}
  for _,v in ipairs(model) do ns[neighborKey(v.x,v.y,v.z)] = true end
  local faces = {}
  for _,v in ipairs(model) do
    local vf = visibleFacesForVoxel(v, ns)
    for _,fn in ipairs(vf) do faces[#faces+1] = { voxel = v, face = fn, color = v.color } end
  end
  return faces
end

function shading.apply(model, params, cam)
  local faces = buildFaces(model)
  params.rotationMatrix = params.rotationMatrix or cam.rotationMatrix
  params.viewDir = params.viewDir or cam.viewDir

  local out = {}
  for _,e in ipairs(faces) do
    local color = e.color
    if params.shadingMode == "Stack" and params.fxStack then
      color = fxStack.shadeFace(params, e.face, e.color)
    else
      local c = e.color or { r=255,g=255,b=255,a=255 }
      local lum = ((c.r*0.299 + c.g*0.587 + c.b*0.114) / 255)
      if e.face == "top" then lum = math.min(1.0, lum * 1.05) end
      color = { r = math.floor(c.r * lum), g = math.floor(c.g * lum), b = math.floor(c.b * lum), a = c.a or 255 }
    end
    out[#out+1] = { x = e.voxel.x, y = e.voxel.y, z = e.voxel.z, face = e.face, color = color }
  end
  return out
end

return shading