-- render/preview/model.lua
-- Robust voxel extraction from Aseprite sprite (port of original logic)
local model = {}

-- Helper to read pixel color robustly (handles Color tables and indexed values)
local function readPixelColor(img, x, y)
  local ok, pix = pcall(function() return img:getPixel(x, y) end)
  if not ok or not pix then return nil end
  if type(pix) == "table" then
    return { r = pix.r or pix.red or 255, g = pix.g or pix.green or 255, b = pix.b or pix.blue or 255, a = pix.a or pix.alpha or 255 }
  elseif type(pix) == "number" then
    -- Indexed/greyscale: treat non-zero as opaque white
    if pix == 0 then return nil end
    return { r = 255, g = 255, b = 255, a = 255 }
  else
    return nil
  end
end

-- Generate voxel model: iterate layers (image layers), map layer order to z
function model.generateVoxelModel(sprite)
  if not sprite then return {} end
  local frame = app.activeFrame or 1
  local voxels = {}
  for layerIndex, layer in ipairs(sprite.layers) do
    if layer.isImage then
      local z = layerIndex - 1
      local cel = layer:cel(frame)
      if cel and cel.image then
        local img = cel.image
        local bounds = cel.bounds or { x = 0, y = 0 }
        local offX = bounds.x or 0
        local offY = bounds.y or 0
        for yy = 0, img.height - 1 do
          for xx = 0, img.width - 1 do
            local color = readPixelColor(img, xx, yy)
            if color and color.a and color.a > 0 then
              local vx = offX + xx
              local vy = offY + yy
              voxels[#voxels + 1] = { x = vx, y = vy, z = z, color = color }
            end
          end
        end
      end
    end
  end
  return voxels
end

function model.calculateMiddlePoint(voxelModel)
  local minX, minY, minZ = math.huge, math.huge, math.huge
  local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
  for _, v in ipairs(voxelModel or {}) do
    if v.x < minX then minX = v.x end
    if v.y < minY then minY = v.y end
    if v.z < minZ then minZ = v.z end
    if v.x > maxX then maxX = v.x end
    if v.y > maxY then maxY = v.y end
    if v.z > maxZ then maxZ = v.z end
  end
  if minX == math.huge then
    return { x = 0, y = 0, z = 0, sizeX = 0, sizeY = 0, sizeZ = 0, _bounds = {} }
  end
  local sizeX = (maxX - minX + 1)
  local sizeY = (maxY - minY + 1)
  local sizeZ = (maxZ - minZ + 1)
  local mp = {
    x = (minX + maxX) / 2,
    y = (minY + maxY) / 2,
    z = (minZ + maxZ) / 2,
    sizeX = sizeX, sizeY = sizeY, sizeZ = sizeZ,
    _bounds = { minX = minX, minY = minY, minZ = minZ, maxX = maxX, maxY = maxY, maxZ = maxZ }
  }
  return mp
end

return model