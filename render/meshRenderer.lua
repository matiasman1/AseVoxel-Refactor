-- meshRenderer.lua: scanline triangle fill (used by raster)
local meshRenderer = {}

local function edgeIntersections(scanY, p0, p1)
  if (p0.y <= scanY and p1.y > scanY) or (p1.y <= scanY and p0.y > scanY) then
    local t = (scanY - p0.y) / (p1.y - p0.y)
    return p0.x + t * (p1.x - p0.x)
  end
  return nil
end

function meshRenderer.fillTriangle(image, p0, p1, p2, color)
  local y0 = math.max(0, math.floor(math.min(p0.y, p1.y, p2.y)))
  local y2 = math.min(image.height-1, math.ceil(math.max(p0.y, p1.y, p2.y)))
  for y = y0, y2 do
    local scanY = y + 0.5
    local xs = {}
    local x01 = edgeIntersections(scanY, p0, p1)
    local x12 = edgeIntersections(scanY, p1, p2)
    local x02 = edgeIntersections(scanY, p0, p2)
    if x01 then xs[#xs+1] = x01 end
    if x12 then xs[#xs+1] = x12 end
    if x02 then xs[#xs+1] = x02 end
    if #xs >= 2 then
      table.sort(xs)
      for k = 1, #xs, 2 do
        local x0 = xs[k]
        local x1 = xs[k+1] or x0
        if x1 < x0 then x0,x1 = x1,x0 end
        local startX = math.max(0, math.floor(x0 + 0.5))
        local endX   = math.min(image.width-1, math.floor(x1 - 0.5))
        for x = startX, endX do
          image:drawPixel(x, y, color)
        end
      end
    end
  end
end

function meshRenderer.fillQuad(image, pts, color)
  meshRenderer.fillTriangle(image, pts[1], pts[2], pts[3], color)
  meshRenderer.fillTriangle(image, pts[1], pts[3], pts[4], color)
end

return meshRenderer