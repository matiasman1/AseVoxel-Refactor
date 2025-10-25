-- fx/fxStack.lua
-- Ported core FX Stack logic (shading face selection and module application).
local fxStack = {}

fxStack.TOP_THRESHOLD = 0.25
fxStack.FACE_ORDER = { "top","bottom","front","back","left","right" }
fxStack.FACESHADE_DISPLAY_ORDER = { "top","bottom","left","right","front","back" }

fxStack.LOCAL_NORMALS = {
  top    = {0,  -1,  0},
  bottom = {0,   1,  0},
  front  = {0,   0, -1},
  back   = {0,   0,  1},
  left   = {-1,  0,  0},
  right  = {1,   0,  0},
}

local function dot3(a,b)
  return (a[1]*b[1] + a[2]*b[2] + a[3]*b[3])
end

-- Rotate local normals using a 3x3 matrix and compute dot with viewDir
function fxStack.computeRotatedNormals(rotationMatrix, viewDir)
  local rot = rotationMatrix or {1,0,0,0,1,0,0,0,1}
  local function apply(n)
    return {
      rot[1]*n[1] + rot[2]*n[2] + rot[3]*n[3],
      rot[4]*n[1] + rot[5]*n[2] + rot[6]*n[3],
      rot[7]*n[1] + rot[8]*n[2] + rot[9]*n[3]
    }
  end

  local out = {}
  for name, ln in pairs(fxStack.LOCAL_NORMALS) do
    local rn = apply(ln)
    local d = (rn[1] * (viewDir[1] or 0)) + (rn[2] * (viewDir[2] or 0)) + (rn[3] * (viewDir[3] or 0))
    out[name] = { dot = d, normal = rn }
  end
  return out
end

-- Select iso face pair (legacy) based on rotated normals
function fxStack.selectIsoFaces(rotInfo)
  local visibles = {}
  for name,info in pairs(rotInfo) do
    if info.dot and info.dot > 0 then visibles[name] = true end
  end
  local pairsOrdered = {
    {"front","right"},
    {"right","back"},
    {"back","left"},
    {"left","front"}
  }
  local best, score = nil, -1
  for _,pr in ipairs(pairsOrdered) do
    local a,b = pr[1], pr[2]
    if visibles[a] and visibles[b] then
      local s = (rotInfo[a].dot or 0) + (rotInfo[b].dot or 0)
      if s > score then score = s; best = { first = a, second = b } end
    end
  end
  return best
end

-- Apply one module (module format: same as original fx modules)
local function applyModule(module, faceName, faceRoleIso, baseColor, voxelColorOriginal)
  if module.scope=="material" and module.materialColor then
    local mc = module.materialColor
    baseColor = { r = mc.r or baseColor.r, g = mc.g or baseColor.g, b = mc.b or baseColor.b, a = baseColor.a }
  end

  if type(module.shadeFace) == "function" then
    local ok, res = pcall(module.shadeFace, module, faceName, baseColor, voxelColorOriginal)
    if ok and type(res) == "table" then return res end
  end

  return baseColor
end

-- Main shading entry: params.fxStack.modules expected
function fxStack.shadeFace(params, faceName, voxelColor)
  local stack = params.fxStack and params.fxStack.modules
  if not stack or #stack == 0 then return voxelColor end

  if not params._frameIsoCache then
    params._frameIsoCache = true
  end

  local baseColor = { r = voxelColor.r or voxelColor.red or 255, g = voxelColor.g or voxelColor.green or 255, b = voxelColor.b or voxelColor.blue or 255, a = voxelColor.a or voxelColor.alpha or 255 }
  local role = faceName

  local out = baseColor
  for i = 1, #stack do
    local module = stack[i]
    out = applyModule(module, faceName, role, out, voxelColor)
  end
  return out
end

return fxStack