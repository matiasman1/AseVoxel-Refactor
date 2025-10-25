-- Rasterization to Aseprite Image. Phase 2 will port the original renderer.
local raster = {}

function raster.draw(model, params, cam)
  -- Create a transparent placeholder image to prevent crashes
  local size = params.canvasSize or 200
  local image = Image(size, size, image and image.colorMode or ColorMode.RGBA)
  -- Optional: draw a simple crosshair to indicate output exists
  local c = Color(0,0,0,0)
  for i=0,size-1 do
    image:drawPixel(i, math.floor(size/2), c)
    image:drawPixel(math.floor(size/2), i, c)
  end
  return image
end

return raster