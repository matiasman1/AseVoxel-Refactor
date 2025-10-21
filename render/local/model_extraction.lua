-- Convert Aseprite sprite into voxel model + basic geometry helpers

local M = {}

local function activeFrame()
  return (app.activeFrame and app.activeFrame.frameNumber) or 1
end

local function visibleLayers(sprite)
  local out = {}
  local function rec(layer)
    if layer.isVisible then
      if #layer.layers > 0 then
        for _,l in ipairs(layer.layers) do rec(l) end
      else
        out[#out+1] = layer
      end
    end
  end
  for _,l in ipairs(sprite.layers) do rec(l) end
  return out
end

local function pixelToColor(px)
  local r = app.pixelColor.rgbaR(px)
  local g = app.pixelColor.rgbaG(px)
  local b = app.pixelColor.rgbaB(px)
  local a = app.pixelColor.rgbaA(px)
  return r,g,b,a
end

local function celImage(layer, frame)
  local cel = layer:cel(frame)
  if not cel or not cel.image then return nil, 0, 0 end
  return cel.image, cel.position.x, cel.position.y
end

local function layerVoxels(layer, frame, z)
  local img, ox, oy = celImage(layer, frame)
  local vox = {}
  if not img then return vox end
  for y = 0, img.height-1 do
    for x = 0, img.width-1 do
      local px = img:getPixel(x, y)
      local r,g,b,a = pixelToColor(px)
      if a and a > 0 then
        vox[#vox+1] = { x=x+ox, y=y+oy, z=z, color={r=r,g=g,b=b,a=a} }
      end
    end
  end
  return vox
end

function M.generateVoxelModel(sprite)
  if not sprite then return {} end
  local frame = activeFrame()
  local layers = visibleLayers(sprite)
  local model = {}
  for i=#layers,1,-1 do
    local z = (#layers - i) -- topmost -> z=0
    local lv = layerVoxels(layers[i], frame, z)
    for _,v in ipairs(lv) do model[#model+1] = v end
  end
  return model
end

function M.calculateModelBounds(model)
  local b = {minX=math.huge,minY=math.huge,minZ=math.huge,maxX=-math.huge,maxY=-math.huge,maxZ=-math.huge}
  for _,v in ipairs(model or {}) do
    if v.x<b.minX then b.minX=v.x end; if v.x>b.maxX then b.maxX=v.x end
    if v.y<b.minY then b.minY=v.y end; if v.y>b.maxY then b.maxY=v.y end
    if v.z<b.minZ then b.minZ=v.z end; if v.z>b.maxZ then b.maxZ=v.z end
  end
  if b.minX==math.huge then return nil end
  return b
end

function M.calculateMiddlePoint(model)
  local b = M.calculateModelBounds(model)
  if not b then return {x=0,y=0,z=0,sizeX=0,sizeY=0,sizeZ=0,_bounds=nil} end
  return {
    x=(b.minX+b.maxX)/2, y=(b.minY+b.maxY)/2, z=(b.minZ+b.maxZ)/2,
    sizeX=(b.maxX-b.minX)+1, sizeY=(b.maxY-b.minY)+1, sizeZ=(b.maxZ-b.minZ)+1,
    _bounds=b
  }
end

return M