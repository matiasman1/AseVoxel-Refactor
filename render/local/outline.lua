-- Outline and simple image post-processing

local M = {}

local function kernel(matrix)
  if matrix == "circle" then
    return {{0,-1},{-1,0},{1,0},{0,1},{-1,-1},{1,-1},{-1,1},{1,1}}
  elseif matrix == "square" then
    return {{0,-1},{-1,0},{1,0},{0,1},{-1,-1},{1,-1},{-1,1},{1,1}}
  elseif matrix == "horizontal" then
    return {{-1,0},{1,0}}
  elseif matrix == "vertical" then
    return {{0,-1},{0,1}}
  end
  return {{0,-1},{-1,0},{1,0},{0,1}}
end

function M.applyOutline(image, settings)
  if not settings or settings.mode ~= "model" and settings.mode ~= "voxels" then return image end
  local k = kernel(settings.matrix or "circle")
  local col = settings.color or Color(0,0,0)
  local out = image:clone()
  for y=0,image.height-1 do
    for x=0,image.width-1 do
      local a = app.pixelColor.rgbaA(image:getPixel(x,y))
      if a>0 then
        for _,o in ipairs(k) do
          local nx,ny = x+o[1], y+o[2]
          if nx>=0 and ny>=0 and nx<image.width and ny<image.height then
            if app.pixelColor.rgbaA(image:getPixel(nx,ny))==0 then
              out:putPixel(nx, ny, app.pixelColor.rgba(col.red or col.r, col.green or col.g, col.blue or col.b, 255))
            end
          end
        end
      end
    end
  end
  return out
end

function M.downsampleInteger(src, factor, mode)
  local f = math.max(1, math.floor(factor or 1))
  if f == 1 then return src:clone() end
  local dst = Image(math.ceil(src.width/f), math.ceil(src.height/f), src.colorMode)
  for y=0,dst.height-1 do
    for x=0,dst.width-1 do
      local sx = math.min(src.width-1, x*f)
      local sy = math.min(src.height-1, y*f)
      dst:putPixel(x, y, src:getPixel(sx, sy))
    end
  end
  return dst
end

return M