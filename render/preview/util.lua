-- render/preview/util.lua
local util = {}

function util.toColor(c)
  if not c then return Color(255,255,255,255) end
  return Color(c.r or c.red or 255, c.g or c.green or 255, c.b or c.blue or 255, c.a or c.alpha or 255)
end

function util.clamp(v, lo, hi)
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

-- Bresenham line for outline
function util.drawLine(img, x0, y0, x1, y1, color)
  local dx = math.abs(x1-x0)
  local sx = x0 < x1 and 1 or -1
  local dy = -math.abs(y1-y0)
  local sy = y0 < y1 and 1 or -1
  local err = dx + dy
  while true do
    if x0 >= 0 and y0 >= 0 and x0 < img.width and y0 < img.height then
      img:drawPixel(x0, y0, color)
    end
    if x0 == x1 and y0 == y1 then break end
    local e2 = 2*err
    if e2 >= dy then err = err + dy; x0 = x0 + sx end
    if e2 <= dx then err = err + dx; y0 = y0 + sy end
  end
end

return util