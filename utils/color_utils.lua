-- utils/color_utils.lua
-- Color calculations extracted from viewerCore

local M = {}

local function clamp01(v) return math.max(0, math.min(1, v)) end

function M.averageRGB(voxels)
  local tr,tg,tb,c = 0,0,0,0
  for _,v in ipairs(voxels or {}) do
    local col = v.color
    if col then tr=tr+(col.r or 0); tg=tg+(col.g or 0); tb=tb+(col.b or 0); c=c+1 end
  end
  if c==0 then return 128,128,128 end
  return tr/c, tg/c, tb/c
end

function M.contrastColor(voxels)
  local r,g,b = M.averageRGB(voxels)
  local brightness = clamp01((r*0.299 + g*0.587 + b*0.114)/255)
  return (brightness > 0.5) and Color(48,48,48) or Color(200,200,200)
end

return M