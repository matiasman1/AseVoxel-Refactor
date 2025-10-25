-- raster.lua: project quads, paint with painter's algorithm, optional outline
local mathUtils = require("mathUtils")
local util = require("util")
local meshRenderer = require("meshRenderer")

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

local function drawOutline(img, pts, color)
  util.drawLine(img, pts[1].x, pts[1].y, pts[2].x, pts[2].y, color)
  util.drawLine(img, pts[2].x, pts[2].y, pts[3].x, pts[3].y, color)
  util.drawLine(img, pts[3].x, pts[3].y, pts[4].x, pts[4].y, color)
  util.drawLine(img, pts[4].x, pts[4].y, pts[1].x, pts[1].y, color)
end

function raster.draw(faces, params, cam)
  local canvasSize = params.canvasSize or 200
  local scale = params.scale or params.scaleLevel or 1.0
  local mp = params.middlePoint or { x=0,y=0,z=0, sizeX=0,sizeY=0,sizeZ=0 }
  local img = Image(canvasSize, canvasSize, ColorMode.RGBA)
  local polys = {}

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
    polys[#polys+1] = { pts = pts2d, color = util.toColor(f.color), depth = avgDepth }
  end

  table.sort(polys, function(a,b) return a.depth < b.depth end)
  for _,p in ipairs(polys) do
    meshRenderer.fillQuad(img, p.pts, p.color)
    if params.enableOutline then
      local oc = params.outlineColor or { r=0,g=0,b=0,a=255 }
      drawOutline(img, p.pts, util.toColor(oc))
    end
  end

  return img
end

return raster