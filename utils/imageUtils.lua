-- imageUtils: basic helpers; extend with original implementations as needed
local imageUtils = {}

function imageUtils.copyImage(src)
  local img = Image(src.width, src.height, src.colorMode)
  img:drawImage(src, 0, 0)
  return img
end

return imageUtils