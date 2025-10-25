-- Preview model helpers: generate voxel model and calculate middle point
-- (Phase 2: implement voxel extraction from an Aseprite sprite)
local model = {}

-- Generate a voxel model from a sprite.
-- Returns an array of voxels { x, y, z, color = { r,g,b,a } }
-- We map layers to Z (bottom-most layer -> z=0, next -> z=1, ...).
-- Supports image cels with position offsets.
function model.generateVoxelModel(sprite)
  if not sprite then return {} end

  local voxels = {}
  -- Determine the target frame (use activeFrame or 1)
  local frame = app.activeFrame or 1

  -- Layers are stacked: lower index is bottom.
  -- We'll assign z = layerIndex-1 for each layer that contains image cels.
  for layerIndex, layer in ipairs(sprite.layers) do
    if layer.isImage then
      local z = layerIndex - 1
      local cel = layer:cel(frame)
      if cel and cel.image then
        local img = cel.image
        local bounds = cel.bounds or { x = 0, y = 0 }
        local offX = bounds.x or 0
        local offY = bounds.y or 0
        local w, h = img.width, img.height
        for yy = 0, h-1 do
          for xx = 0, w-1 do
            -- image:getPixel returns pixel value or color; robustly handle Color or number
            local ok, pix = pcall(function() return img:getPixel(xx, yy) end)
            if ok and pix then
              -- Accept either Color-like (table) or packed integer (indexed colors)
              local r,g,b,a
              if type(pix) == "table" and (pix.r or pix.red) then
                r = pix.r or pix.red or 0
                g = pix.g or pix.green or 0
                b = pix.b or pix.blue or 0
                a = pix.a or pix.alpha or 255
              elseif type(pix) == "number" then
                -- Indexed/paletted sprites: try to convert using sprite.palette if available
                -- Fallback: treat non-zero value as opaque white
                if pix == 0 then a = 0 else a = 255 end
                r, g, b = 255, 255, 255
              else
                -- Unknown pixel type: skip
                a = 0
              end

              if a and a > 0 then
                local vx = offX + xx
                local vy = offY + yy
                local color = { r = r, g = g, b = b, a = a }
                voxels[#voxels + 1] = { x = vx, y = vy, z = z, color = color }
              end
            end
          end
        end
      end
    end
  end

  return voxels
end

-- Calculate middle point and sizes for a voxel model
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
    sizeX = sizeX,
    sizeY = sizeY,
    sizeZ = sizeZ,
    _bounds = { minX = minX, minY = minY, minZ = minZ, maxX = maxX, maxY = maxY, maxZ = maxZ }
  }
  return mp
end

return model