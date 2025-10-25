-- render/preview/downsample.lua
-- Downsample / post-processing (kept compact)
local downsample = {}

function downsample.downsample(img, params, metrics)
  -- No-op if no downsample required; placeholder for full original logic (AA, gamma)
  return img
end

return downsample