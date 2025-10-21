-- Minimal OBJ exporter for voxel models

local C = require("render.local.constants")

local E = {}

local function write(f, s) f:write(s) end

local function faceVerts(x,y,z,s)
  local v = {}
  for i=1,#C.UNIT_CUBE_VERTICES do
    local p = C.UNIT_CUBE_VERTICES[i]
    v[i] = { x + p[1]*s, y + p[2]*s, z + p[3]*s }
  end
  return v
end

local function writeVoxel(f, v, scale, indexBase)
  local verts = faceVerts(v.x, v.y, v.z, scale)
  for i=1,8 do write(f, string.format("v %.6f %.6f %.6f\n", verts[i].x, verts[i].y, verts[i].z)) end
  local col = v.color or {r=255,g=255,b=255,a=255}
  write(f, string.format("usemtl c_%d_%d_%d\n", col.r or col.red, col.g or col.green, col.b or col.blue))
  local faces = {C.FACE_DEFS.front, C.FACE_DEFS.back, C.FACE_DEFS.left, C.FACE_DEFS.right, C.FACE_DEFS.top, C.FACE_DEFS.bottom}
  for _,idx in ipairs(faces) do
    write(f, string.format("f %d %d %d %d\n", indexBase+idx[1], indexBase+idx[2], indexBase+idx[3], indexBase+idx[4]))
  end
  return indexBase + 8
end

local function writeMtl(path, mats)
  local ok, mf = pcall(function() return io.open(path, "w") end)
  if not ok or not mf then return end
  for k,_ in pairs(mats) do
    local r,g,b = k[1],k[2],k[3]
    mf:write(string.format("newmtl c_%d_%d_%d\nKd %.3f %.3f %.3f\n", r,g,b, r/255, g/255, b/255))
  end
  mf:close()
end

function E.exportOBJ(voxels, filePath, options)
  local f, err = io.open(filePath, "w"); if not f then return false, err end
  local scale = (options and options.scaleModel) or 1.0
  local mtlPath = (filePath:gsub("%.obj$",".mtl"))
  local mats = {}
  write(f, "o voxelmodel\n")
  write(f, string.format("mtllib %s\n", app.fs.fileName(mtlPath)))
  local idx = 0
  for _,v in ipairs(voxels or {}) do
    local c = v.color or {}
    local r = c.r or c.red or 255; local g = c.g or c.green or 255; local b = c.b or c.blue or 255
    mats[{r,g,b}] = true
    idx = writeVoxel(f, v, scale, idx)
  end
  f:close()
  writeMtl(mtlPath, mats)
  return true
end

return E