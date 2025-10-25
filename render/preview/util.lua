-- render/preview/util.lua
local util = {}

function util.toColor(c)
  if not c then return Color(255,255,255,255) end
  return Color(c.r or c.red or 255, c.g or c.green or 255, c.b or c.blue or 255, c.a or c.alpha or 255)
end

return util