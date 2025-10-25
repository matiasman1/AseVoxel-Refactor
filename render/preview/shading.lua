-- shading.lua: convert voxel list to face list + shade with fxStack or basic shading.
local fxStack = require("fx.fxStack")
local mathUtils = require("utils.mathUtils")

local shading = {}

-- Determine visible faces per voxel by checking neighbor set (neighbors keyed "x:y:z")
local function visibleFacesForVoxel(v, neighborSet)
  local faces = {}
  -- neighbor positions
  local nx = { {1,0,0,"right"}, {-1,0,0,"left"}, {0,1,0,"bottom"}, {0,-1,0,"top"}, {0,0,1,"back"}, {0,0,-1,"front"} }
  for _,off in ipairs(nx) do
    local tx,ty,tz,faceName = v.x + off[1], v.y + off[2], v.z + off[3], off[4]
    local key = string.format("%d:%d:%d", tx, ty, tz)
    if not neighborSet[key] then
      faces[#faces+1] = faceName
    end
  end
  return faces
end

-- Convert voxel model to list of face entries: { voxel=..., face="top", color=..., verts={{x,y,z},...} }
local function buildFaces(model, params)
  local neighborSet = {}
  for _,v in ipairs(model) do
    local k = string.format("%d:%d:%d", v.x, v.y, v.z)
    neighborSet[k] = true
  end

  local faces = {}
  for _,v in ipairs(model) do
    local vf = visibleFacesForVoxel(v, neighborSet)
    for _,faceName in ipairs(vf) do
      faces[#faces+1] = { voxel = v, face = faceName, color = v.color }
    end
  end
  return faces
end

-- Convert faces to shaded faces (apply fxStack or basic shading)
function shading.apply(model, params, cam)
  local faces = buildFaces(model, params)

  -- Prepopulate rotationMatrix & viewDir for fxStack
  params.rotationMatrix = params.rotationMatrix or cam.rotationMatrix
  params.viewDir = params.viewDir or cam.viewDir

  local shaded = {}
  for _, entry in ipairs(faces) do
    local v = entry.voxel
    local f = entry.face

    local outColor = entry.color
    if params.shadingMode == "Stack" and params.fxStack then
      outColor = fxStack.shadeFace(params, f, entry.color)
    else
      -- Basic shading: modulate by simple luminance as placeholder
      local c = entry.color or { r=255,g=255,b=255,a=255 }
      local lum = ((c.r*0.299 + c.g*0.587 + c.b*0.114) / 255)
      -- Slightly dim faces that are not "top"
      if f == "top" then lum = math.min(1.0, lum * 1.05) end
      outColor = { r = math.floor(c.r * lum), g = math.floor(c.g * lum), b = math.floor(c.b * lum), a = c.a or 255 }
    end

    shaded[#shaded+1] = {
      x = v.x, y = v.y, z = v.z,
      face = f,
      color = outColor
    }
  end

  return shaded
end

return shading