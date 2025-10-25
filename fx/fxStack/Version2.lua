-- fx/fxStack.lua
-- Ported core FX Stack logic (shading face selection and module application).
-- This file contains the main shading utilities used by the preview renderer.
local fxStack = {}

-- Constants / defaults
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

-- Helper: dot product for two 3-element tables
local function dot3(a,b)
  return (a[1]*b[1] + a[2]*b[2] + a[3]*b[3])
end

-- Compute rotated normals given a rotation matrix (3x3 array) and viewDir vector {x,y,z}
-- Returns table: { top = {dot=..., normal={...}}, ... }
function fxStack.computeRotatedNormals(rotationMatrix, viewDirVec)
  local rot = rotationMatrix or {1,0,0,0,1,0,0,0,1}
  local vd = viewDirVec or {0,0,1}
  -- Build rotation as function applying matrix to local normals
  local function applyRot(n)
    return {
      rot[1]*n[1] + rot[2]*n[2] + rot[3]*n[3],
      rot[4]*n[1] + rot[5]*n[2] + rot[6]*n[3],
      rot[7]*n[1] + rot[8]*n[2] + rot[9]*n[3]
    }
  end

  local out = {}
  for faceName, localN in pairs(fxStack.LOCAL_NORMALS) do
    local rn = applyRot(localN)
    local d = rn[1]*vd[1] + rn[2]*vd[2] + rn[3]*vd[3]
    out[faceName] = { dot = d, normal = rn }
  end
  return out
end

-- Select iso faces (legacy alpha roles) based on rotated normals
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

  local best, nilScore = nil, -1
  for _, pr in ipairs(pairsOrdered) do
    local a,b = pr[1], pr[2]
    if visibles[a] and visibles[b] then
      local score = (rotInfo[a].dot or 0) + (rotInfo[b].dot or 0)
      if score > nilScore then
        nilScore = score
        best = { first = a, second = b }
      end
    end
  end
  return best
end

-- Apply single fx module to a face color (module format is same as original fx modules)
local function applyModule(module, faceName, faceRoleIso, baseColor, voxelColorOriginal)
  -- Material scope check (original color)
  if module.scope == "material" and module.materialColor then
    local mc = module.materialColor
    -- blend module.materialColor with voxel as required (simplified)
    baseColor = { r = mc.r or baseColor.r, g = mc.g or baseColor.g, b = mc.b or baseColor.b, a = baseColor.a }
  end

  -- Module provides shadeFace(fileld) function in original; emulate calling it if present
  if type(module.shadeFace) == "function" then
    local ok, res = pcall(module.shadeFace, module, faceName, baseColor, voxelColorOriginal)
    if ok and type(res) == "table" then
      return res
    end
  end

  -- Default: return base color unchanged
  return baseColor
end

-- Shade a face using the stack modules and the rules (literal role mapping)
-- params.rotationMatrix and params.viewDir expected; params.fxStack is the user stack data (modules array)
function fxStack.shadeFace(params, faceName, voxelColor)
  local stack = params.fxStack and params.fxStack.modules
  if not stack or #stack == 0 then return voxelColor end

  if not params._frameIsoCache then
    -- Precompute mapping helpers if necessary; in simplified form we skip caches here
    params._frameIsoCache = true
  end

  local baseColor = { r = voxelColor.r or voxelColor.red or 255, g = voxelColor.g or voxelColor.green or 255, b = voxelColor.b or voxelColor.blue or 255, a = voxelColor.a or voxelColor.alpha or 255 }
  -- Compute role iso selection (legacy) - simplified path
  local role = faceName

  local out = baseColor
  for i = 1, #stack do
    local module = stack[i]
    out = applyModule(module, faceName, role, out, voxelColor)
  end

  return out
end

return fxStack