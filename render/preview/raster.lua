-- Rasterization: project voxels and draw them to an Image
local mathUtils = require("utils.mathUtils")

local raster = {}

-- Draw voxels as small squares onto an Image.
-- model: array of voxels {x,y,z,color,brightness}
-- params: canvasSize, pixelSize, middlePoint, scaleLevel, etc.
-- cam: contains rotationMatrix, focalLength, orthogonal
function raster.draw(model, params, cam)
  local canvasSize = params.canvasSize or 200
  local pixelSize = params.pixelSize or 1
  local scale = params.scale or params.scaleLevel or 1.0
  local mp = params.middlePoint or { x = 0, y = 0, z = 0 }

  -- Prepare blank image
  local img = Image(canvasSize, canvasSize, ColorMode.RGBA)
  -- Transparent background by default
  local bg = Color(0,0,0,0)

  -- Project function: world 3D -> 2D canvas coordinates
  local function project(p)
    -- translate to center
    local rx = p.x - mp.x
    local ry = p.y - mp.y
    local rz = p.z - mp.z

    -- apply rotation
    local M = cam.rotationMatrix
    local pr = { x = rx, y = ry, z = rz }
    if M then
      pr = mathUtils.applyRotation(M, pr)
    end

    -- Simple perspective: camera looking down +Z
    if cam.orthogonal then
      -- map x,y to canvas
      local cx = math.floor((pr.x * scale) + (canvasSize / 2) + 0.5)
      local cy = math.floor((pr.y * -scale) + (canvasSize / 2) + 0.5)
      return cx, cy, pr.z
    else
      local f = cam.focalLength or (canvasSize/2)
      local zoffset = (pr.z + (mp and math.max(mp.sizeX or 0, mp.sizeY or 0) or 1)) + 1
      if zoffset <= 0.01 then zoffset = 0.01 end
      local sx = (pr.x * f) / (zoffset)
      local sy = (pr.y * f) / (zoffset)
      local cx = math.floor(sx + (canvasSize / 2) + 0.5)
      local cy = math.floor(-sy + (canvasSize / 2) + 0.5)
      return cx, cy, pr.z
    end
  end

  -- Depth sort: far -> near so later draws overlap nearer voxels last
  table.sort(model, function(a,b) return (a.z or 0) < (b.z or 0) end)

  -- Draw voxels
  for i, v in ipairs(model) do
    local cx, cy, depth = project(v)
    if cx and cy and cx >= 0 and cy >= 0 and cx < canvasSize and cy < canvasSize then
      -- Color: prefer v.color; brightness may be used later
      local c = v.color or { r = 255, g = 255, b = 255, a = 255 }
      local col = Color(c.r or c.red or 255, c.g or c.green or 255, c.b or c.blue or 255, c.a or c.alpha or 255)

      -- Draw a square of pixelSize (clamp to canvas)
      local half = math.floor(pixelSize / 2)
      for oy = -half, half do
        for ox = -half, half do
          local px = cx + ox
          local py = cy + oy
          if px >= 0 and py >= 0 and px < canvasSize and py < canvasSize then
            img:drawPixel(px, py, col)
          end
        end
      end
    end
  end

  return img
end

return raster