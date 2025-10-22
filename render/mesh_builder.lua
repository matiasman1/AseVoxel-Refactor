-- render/mesh_builder.lua
-- Builds triangle meshes from voxel models

local M = {}

-- Cube layout aligned with exporters (OBJ/PLY/STL), unit cube centered at voxel
local CUBE_VERTS = {
  {-0.5,-0.5,-0.5}, { 0.5,-0.5,-0.5}, { 0.5, 0.5,-0.5}, {-0.5, 0.5,-0.5}, -- back
  {-0.5,-0.5, 0.5}, { 0.5,-0.5, 0.5}, { 0.5, 0.5, 0.5}, {-0.5, 0.5, 0.5}, -- front
}

-- Face quads (consistent with export code), each as 4 vertex indices (1-based)
local FACES = {
  back   = {4,3,2,1}, -- z = -0.5
  front  = {5,6,7,8}, -- z = +0.5
  right  = {2,3,7,6}, -- +X
  left   = {1,5,8,4}, -- -X
  top    = {4,8,7,3}, -- +Y
  bottom = {1,2,6,5}, -- -Y
}

-- Neighbor offsets to detect interior faces
local NEIGHBORS = {
  front  = {dx= 0, dy= 0, dz= 1},
  back   = {dx= 0, dy= 0, dz=-1},
  right  = {dx= 1, dy= 0, dz= 0},
  left   = {dx=-1, dy= 0, dz= 0},
  top    = {dx= 0, dy= 1, dz= 0},
  bottom = {dx= 0, dy=-1, dz= 0},
}

local function key(x, y, z)
  return tostring(x) .. "," .. tostring(y) .. "," .. tostring(z)
end

-- Calculate the bounds of the mesh
function M.calculateMeshBounds(mesh)
  if not mesh or not mesh.vertices or #mesh.vertices == 0 then
    return nil
  end
  
  local minX, maxX = math.huge, -math.huge
  local minY, maxY = math.huge, -math.huge
  local minZ, maxZ = math.huge, -math.huge
  
  for _, vertex in ipairs(mesh.vertices) do
    minX = math.min(minX, vertex[1])
    maxX = math.max(maxX, vertex[1])
    minY = math.min(minY, vertex[2])
    maxY = math.max(maxY, vertex[2])
    minZ = math.min(minZ, vertex[3])
    maxZ = math.max(maxZ, vertex[3])
  end
  
  return {
    minX = minX,
    maxX = maxX,
    minY = minY,
    maxY = maxY,
    minZ = minZ,
    maxZ = maxZ
  }
end

-- Calculate the middle point of the mesh
function M.calculateMiddlePoint(mesh)
  local bounds = M.calculateMeshBounds(mesh)
  if not bounds then
    return {x = 0, y = 0, z = 0, sizeX = 0, sizeY = 0, sizeZ = 0}
  end
  
  return {
    x = (bounds.minX + bounds.maxX) / 2,
    y = (bounds.minY + bounds.maxY) / 2,
    z = (bounds.minZ + bounds.maxZ) / 2,
    sizeX = bounds.maxX - bounds.minX,
    sizeY = bounds.maxY - bounds.minY,
    sizeZ = bounds.maxZ - bounds.minZ
  }
end

-- Builds a triangle mesh:
-- returns {
--   vertices = { {x,y,z}, ... },
--   triangles = { {i1,i2,i3, color={r,g,b,a}}, ... },
--   bounds = { minX, maxX, minY, maxY, minZ, maxZ }
-- }
function M.buildMesh(voxels)
  local mesh = { vertices = {}, triangles = {}, bounds = nil }
  if not voxels or #voxels == 0 then return mesh end

  -- Build occupancy map
  local occ = {}
  local minX, maxX = math.huge, -math.huge
  local minY, maxY = math.huge, -math.huge
  local minZ, maxZ = math.huge, -math.huge
  
  for _, v in ipairs(voxels) do
    occ[key(v.x, v.y, v.z)] = true
    if v.x < minX then minX = v.x end
    if v.x > maxX then maxX = v.x end
    if v.y < minY then minY = v.y end
    if v.y > maxY then maxY = v.y end
    if v.z < minZ then minZ = v.z end
    if v.z > maxZ then maxZ = v.z end
  end
  
  mesh.bounds = { minX=minX, maxX=maxX, minY=minY, maxY=maxY, minZ=minZ, maxZ=maxZ }

  local verts = mesh.vertices
  local tris  = mesh.triangles
  local vcount = 0

  local function emitFace(vx, vy, vz, faceName, color)
    local q = FACES[faceName]
    if not q then return end

    -- Build the 8 cube vertices for this voxel (not sharing vertices across voxels, simple first pass)
    local baseIndex = vcount + 1
    for i=1,8 do
      local cv = CUBE_VERTS[i]
      verts[#verts+1] = { vx + cv[1], vy + cv[2], vz + cv[3] }
    end
    vcount = vcount + 8

    -- Emit two triangles for the face quad: (a,b,c) and (a,c,d)
    local a = baseIndex + q[1] - 1
    local b = baseIndex + q[2] - 1
    local c = baseIndex + q[3] - 1
    local d = baseIndex + q[4] - 1
    
    tris[#tris+1] = { a, b, c, color = { r=color.r or color.red or 255, g=color.g or color.green or 255, b=color.b or color.blue or 255, a=color.a or color.alpha or 255 } }
    tris[#tris+1] = { a, c, d, color = { r=color.r or color.red or 255, g=color.g or color.green or 255, b=color.b or color.blue or 255, a=color.a or color.alpha or 255 } }
  end

  for _, v in ipairs(voxels) do
    -- For each face, if neighbor exists, skip; otherwise emit face
    for fname, off in pairs(NEIGHBORS) do
      local nx, ny, nz = v.x + off.dx, v.y + off.dy, v.z + off.dz
      if not occ[key(nx, ny, nz)] then
        emitFace(v.x, v.y, v.z, fname, v.color or {r=255,g=255,b=255,a=255})
      end
    end
  end

  return mesh
end

return M