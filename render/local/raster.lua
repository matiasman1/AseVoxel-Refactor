-- 2D raster helpers and cube drawing

local C = require("render.local.constants")
local fxStack = require("render.fx_stack")
local dyn = require("render.local.dynamic_lighting")

local M = {}

local function edgeIntersections(y, a, b)
  if (a[2] <= y and b[2] <= y) or (a[2] > y and b[2] > y) then return nil end
  local t = (y - a[2]) / (b[2] - a[2])
  return a[1] + t*(b[1]-a[1])
end

function M.drawConvexQuad(img, pts, color)
  local minY, maxY = math.huge, -math.huge
  for i=1,4 do minY=math.min(minY, pts[i][2]); maxY=math.max(maxY, pts[i][2]) end
  minY = math.max(0, math.floor(minY)); maxY = math.min(img.height-1, math.ceil(maxY))
  for y=minY,maxY do
    local xs = {}
    for i=1,4 do
      local a, b = pts[i], pts[(i%4)+1]
      local x = edgeIntersections(y+0.5, a, b)
      if x then xs[#xs+1] = x end
    end
    table.sort(xs)
    for i=1,#xs,2 do
      local x0 = math.max(0, math.floor(xs[i] or 0))
      local x1 = math.min(img.width-1, math.ceil(xs[i+1] or x0))
      for x=x0,x1 do img:putPixel(x, y, app.pixelColor.rgba(color.r,color.g,color.b,color.a or 255)) end
    end
  end
end

local function faceDepth(vs, idx)
  local i1,i2,i3,i4 = idx[1],idx[2],idx[3],idx[4]
  return (vs[i1][3]+vs[i2][3]+vs[i3][3]+vs[i4][3]) * 0.25
end

local function shadeFace(face, base, params, rotM)
  if (params.shadingMode or "Stack") == "Stack" then
    params._frameIsoCache = nil
    return fxStack.shadeFace({ fxStack=params.fxStack, rotationMatrix=rotM, viewDir={0,0,1} }, face, base)
  else
    local k = dyn.faceBrightness(face, rotM, params.lighting)
    return dyn.tintColor(base, k, params.lighting and params.lighting.lightColor)
  end
end

function M.drawVoxel(img, screenVerts, rotM, baseColor, params)
  local faces = C.faceOrder()
  local drawQ = {}
  for _,name in ipairs(faces) do
    local idx = C.FACE_DEFS[name]
    local d = faceDepth(screenVerts, idx)
    local col = shadeFace(name, baseColor, params, rotM)
    drawQ[#drawQ+1] = {depth=d, name=name, idx=idx, color=col}
  end
  table.sort(drawQ, function(a,b) return a.depth > b.depth end)
  for _,f in ipairs(drawQ) do
    local pts = { screenVerts[f.idx[1]], screenVerts[f.idx[2]], screenVerts[f.idx[3]], screenVerts[f.idx[4]] }
    M.drawConvexQuad(img, pts, f.color)
  end
end

return M