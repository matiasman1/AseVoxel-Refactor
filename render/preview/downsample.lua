-- downsample.lua: basic finalize step; hook for AA/downsample
local downsample = {}

-- For parity, we keep a simple no-op (can be extended with real AA/downsample if needed)
function downsample.downsample(image, params, metrics)
  -- Placeholder for AA/downsample to match original; currently returns as-is.
  if metrics then
    metrics.t_downsample_ms = metrics.t_downsample_ms or 0
  end
  return image
end

return downsample