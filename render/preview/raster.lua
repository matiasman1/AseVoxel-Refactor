-- raster.lua: project face quads to 2D and rasterize them to an Image.
local mathUtils = require("utils.mathUtils")
local util = require("render.preview.util")

local raster = {}

-- cube face local vertex definitions (each face is quad of 4 verts)
local FACE_VERTS = {
  top   = { {0,0,0},{1,0,0},{1,0,1},{0,0,1} },
  bottom= { {0,1,0},{0,1,1},{1,1,1},{1,1,0} },
  front = { {0,0,0},{0,1,0},{1,1,0},{1,0,0} },
  back  = { {0,0,1},{1,0,1},{1,1,1},{0,1,1} },
  left  = { {0,0,0},{0,0,1},{0,1,1},{0,1,0} },
  right = { {1,0,0},{1,1,0},{1,1,1},{1,0,1} }
}

-- Project a 3D point (world) to canvas coords
local function projectPoint(px,py,pz, mp, cam, canvasSize, scale)
  local rx = px - mp.x
  local ry = py - mp.y
  local rz = pz - mp.z
  local pr = mathUtils.applyRotation(cam.rotationMatrix, { x = rx, y = ry, z = rz })

  if cam.orthogonal then
    local cx = math.floor((pr.x * scale) + (canvasSize / 2) + 0.5)
    local cy = math.floor((pr.y * -scale) + (canvasSize / 2) + 0.5)
    return cx, cy, pr.z
  else
    local f = cam.focalLength or (canvasSize/2)
    local zoffset = (pr.z + (mp.sizeX or 0) + 1) + 1
    if zoffset <= 0.01 then zoffset = 0.01 end
    local sx = (pr.x * f) / (zoffset)
    local sy = (pr.y * f) / (zoffset)
    local cx = math.floor(sx + (canvasSize / 2) + 0.5)
    local cy = math.floor(-sy + (canvasSize / 2) + 0.5)
    return cx, cy, pr.z
  end
end

-- Triangle rasterization (scanline) - from meshRenderer style approach
local function drawTriangle(image, p0, p1, p2, color)
  -- bounding box clamp
  local w,h = image.width, image.height
  local minX = math.max(0, math.floor(math.min(p0.x,p1.x,p2.x)))
  local maxX = math.min(w-1, math.ceil(math.max(p0.x,p1.x,p2.x)))
  local minY = math.max(0, math.floor(math.min(p0.y,p1.y,p2.y)))
  local maxY = math.min(h-1, math.ceil(math.max(p0.y,p1.y,p2.y)))

  local function edgeFunction(a,b,c)
    return (c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)
  end

  local area = edgeFunction(p0,p1,p2)
  if area == 0 then return end

  for y = minY, maxY do
    for x = minX, maxX do
      local p = { x = x + 0.5, y = y + 0.5 }
      local w0 = edgeFunction(p1,p2,p)
      local w1 = edgeFunction(p2,p0,p)
      local w2 = edgeFunction(p0,p1,p)
      -- barycentric coordinates test
      if (w0 >= 0 and w1 >= 0 and w2 >= 0) or (w0 <= 0 and w1 <= 0 and w2 <= 0) then
        image:drawPixel(x, y, color)
      end
    end
  end
end

-- Draw a quad as two triangles
local function drawQuad(image, pts2d, color)
  drawTriangle(image, pts2d[1], pts2d[2], pts2d[3], color)
  drawTriangle(image, pts2d[1], pts2d[3], pts2d[4], color)
end

-- Main draw entry
-- faces: list of { x,y,z, face, color }
function raster.draw(faces, params, cam)
  local canvasSize = params.canvasSize or 200
  local pixelSize = params.pixelSize or 1
  local scale = params.scale or params.scaleLevel or 1.0
  local mp = params.middlePoint or { x=0,y=0,z=0, sizeX=0, sizeY=0, sizeZ=0 }

  local img = Image(canvasSize, canvasSize, ColorMode.RGBA)

  -- convert faces to projected polygons with depth key
  local polyList = {}
  for _, f in ipairs(faces or {}) do
    local verts_local = FACE_VERTS[f.face]
    local pts2d = {}
    local avgDepth = 0
    for i,vv in ipairs(verts_local) do
      -- local face verts are in cube-space [0..1], add voxel position offset
      local wx = f.x + vv[1]
      local wy = f.y + vv[2]
      local wz = f.z + vv[3]
      local cx, cy, depth = projectPoint(wx,wy,wz, mp, cam, canvasSize, scale)
      pts2d[i] = { x = cx, y = cy, z = depth }
      avgDepth = avgDepth + depth
    end
    avgDepth = avgDepth / #verts_local
    polyList[#polyList+1] = { pts = pts2d, color = util.toColor(f.color), depth = avgDepth }
  end

  -- painter's algorithm: sort by depth (far first)
  table.sort(polyList, function(a,b) return a.depth < b.depth end)

  -- draw polygons
  for _, poly in ipairs(polyList) do
    -- ensure points are in correct order for triangles
    drawQuad(img, poly.pts, poly.color)
  end

  return img
end

return raster