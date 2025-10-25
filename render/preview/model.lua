-- Preview model helpers: generate voxel model and calculate middle point
local model = {}

-- Placeholder: in Phase 2, port the original generateVoxelModel logic verbatim.
function model.generateVoxelModel(sprite)
  -- Walk layers, tiles, etc. For now, return empty to avoid crashes if sprite is nil.
  if not sprite then return {} end
  -- TODO: Port original implementation
  return {}
end

function model.calculateMiddlePoint(voxelModel)
  -- Calculate bounds and center. Keep fields sizeX/sizeY/sizeZ for UI.
  local minX, minY, minZ = math.huge, math.huge, math.huge
  local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
  for _,v in ipairs(voxelModel or {}) do
    if v.x < minX then minX = v.x end
    if v.y < minY then minY = v.y end
    if v.z < minZ then minZ = v.z end
    if v.x > maxX then maxX = v.x end
    if v.y > maxY then maxY = v.y end
    if v.z > maxZ then maxZ = v.z end
  end
  if minX == math.huge then
    return { x=0,y=0,z=0, sizeX=0,sizeY=0,sizeZ=0 }
  end
  return {
    x = (minX + maxX)/2,
    y = (minY + maxY)/2,
    z = (minZ + maxZ)/2,
    sizeX = (maxX - minX + 1),
    sizeY = (maxY - minY + 1),
    sizeZ = (maxZ - minZ + 1)
  }
end

return model