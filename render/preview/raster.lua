-- render/preview/raster.lua
-- Polygon projection + triangle scanline rasterization (meshRenderer-inspired)

local mathUtils = require("utils.mathUtils")
local util = require("render.preview.util")

local raster = {}

local FACE_VERTS = {
  top   = { {0,0,0},{1,0,0},{1,0,1},{0,0,1} },
  bottom= { {0,1,0},{0,1,1},{1,1,1},{1,1,0} },
  front = { {0,0,0},{0,1,0},{1,1,0},{1,0,0} },
  back  = { {0,0,1},{1,0,1},{1,1,1},{0,1,1} },
  left  = { {0,0,0},{0,0,1},{0,1,1},{0,1,0} },
  right = { {1,0,0},{1,1,0},{1,1,1},{1,0,1} }
}

local function projectPoint(px,py,pz, mp, cam, canvasSize, scale)
  local rx = px - mp.x
  local ry = py - mp.y
  local rz = pz - (mp.z or 0)
  local pr = mathUtils.applyRotation(cam.rotationMatrix, { x = rx, y = ry, z = rz })

  if cam.orthogonal then
    local cx = math.floor((pr.x * scale) + (canvasSize/2) + 0.5)
    local cy = math.floor((pr.y * -scale) + (canvasSize/2) + 0.5)
    return cx, cy, pr.z
  else
    local f = cam.focalLength or (canvasSize/2)
    local zoff = (pr.z + (mp.sizeX or 0) + 1) + 1
    if zoff <= 0.01 then zoff = 0.01 end
    local sx = (pr.x * f) / zoff
    local sy = (pr.y * f) / zoff
    local cx = math.floor(sx + (canvasSize/2) + 0.5)
    local cy = math.floor(-sy + (canvasSize/2) + 0.5)
    return cx, cy, pr.z
  end
end

local function edgeFunc(a,b,c)
  return (c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)
end

local function drawTriangle(img, p0, p1, p2, color)
  local w,h = img.width, img.height
  local minX = math.max(0, math.floor(math.min(p0.x,p1.x,p2.x)))
  local maxX = math.min(w-1, math.ceil(math.max(p0.x,p1.x,p2.x)))
  local minY = math.max(0, math.floor(math.min(p0.y,p1.y,p2.y)))
  local maxY = math.min(h-1, math.ceil(math.max(p0.y,p1.y,p2.y)))
  local area = edgeFunc(p0,p1,p2)
  if area == 0 then return end
  for y = minY, maxY do
    for x = minX, maxX do
      local p = { x = x + 0.5, y = y + 0.5 }
      local w0 = edgeFunc(p1,p2,p)
      local w1 = edgeFunc(p2,p0,p)
      local w2 = edgeFunc(p0,p1,p)
      if (w0 >= 0 and w1 >= 0 and w2 >= 0) or (w0 <= 0 and w1 <= 0 and w2 <= 0) then
        img:drawPixel(x, y, color)
      end
    end
  end
end

local function drawQuad(img, pts, color)
  drawTriangle(img, pts[1], pts[2], pts[3], color)
  drawTriangle(img, pts[1], pts[3], pts[4], color)
end

function raster.draw(faces, params, cam)
  local canvasSize = params.canvasSize or 200
  local scale = params.scale or params.scaleLevel or 1.0
  local mp = params.middlePoint or { x = 0, y = 0, z = 0, sizeX = 0, sizeY = 0, sizeZ = 0 }

  local img = Image(canvasSize, canvasSize, ColorMode.RGBA)
  local poly = {}
  for _,f in ipairs(faces or {}) do
    local verts = FACE_VERTS[f.face]
    local pts2d = {}
    local avgDepth = 0
    for i,vv in ipairs(verts) do
      local wx = f.x + vv[1]
      local wy = f.y + vv[2]
      local wz = f.z + vv[3]
      local cx,cy,d = projectPoint(wx,wy,wz, mp, cam, canvasSize, scale)
      pts2d[i] = { x = cx, y = cy, z = d }
      avgDepth = avgDepth + d
    end
    avgDepth = avgDepth / #verts
    poly[#poly+1] = { pts = pts2d, color = util.toColor(f.color), depth = avgDepth }
  end

  table.sort(poly, function(a,b) return a.depth < b.depth end)
  for _,p in ipairs(poly) do drawQuad(img, p.pts, p.color) end

  return img
end

return raster