-- render/modes/mesh_renderer.lua
-- Mesh-based renderer implementation using triangles

local mathUtils = require("utils.math_utils")
local meshBuilder = require("render.mesh_builder")
local debug = require("core.debug")

local M = {}

function M.renderVoxelModel(voxelModel, params)
  debug.log("Using mesh renderer")
  
  -- Build a triangle mesh from the voxel model
  local mesh = meshBuilder.buildMesh(voxelModel)
  
  -- Create a new image to render to
  local width = params.width or params.canvasSize or 200
  local height = params.height or params.canvasSize or 200
  local image = Image(width, height, ColorMode.RGB)
  
  -- Fill with background color (default black)
  local bgColor = params.backgroundColor or Color(0, 0, 0)
  for y = 0, height - 1 do
    for x = 0, width - 1 do
      image:putPixel(x, y, app.pixelColor.rgba(bgColor.red, bgColor.green, bgColor.blue, bgColor.alpha))
    end
  end
  
  -- Calculate view parameters
  local cameraDistance = params.cameraDistance or 200
  local middlePoint = meshBuilder.calculateMiddlePoint(mesh)
  local focalLength = height / (2 * math.tan(math.rad(params.fovDegrees or 45) / 2))
  
  -- Calculate camera position
  local cameraPos = {
    x = middlePoint.x,
    y = middlePoint.y,
    z = middlePoint.z + cameraDistance
  }
  
  -- Project all vertices to 2D
  local projectedVerts = {}
  for i, v in ipairs(mesh.vertices) do
    -- Calculate view-space position
    local dx = v[1] - cameraPos.x
    local dy = v[2] - cameraPos.y
    local dz = v[3] - cameraPos.z
    
    -- Project to screen
    local scale = params.orthogonal and 1 or (focalLength / (-dz))
    local sx = width / 2 + dx * scale
    local sy = height / 2 + dy * scale
    
    projectedVerts[i] = {sx, sy, -dz}  -- Store depth for z-buffer
  end
  
  -- Sort triangles by average depth (back to front)
  local sortedTris = {}
  for i, tri in ipairs(mesh.triangles) do
    local avgDepth = (projectedVerts[tri[1]][3] + projectedVerts[tri[2]][3] + projectedVerts[tri[3]][3]) / 3
    sortedTris[i] = {index = i, depth = avgDepth}
  end
  
  table.sort(sortedTris, function(a, b) return a.depth > b.depth end)
  
  -- Draw triangles
  for _, sortedTri in ipairs(sortedTris) do
    local tri = mesh.triangles[sortedTri.index]
    local v1 = projectedVerts[tri[1]]
    local v2 = projectedVerts[tri[2]]
    local v3 = projectedVerts[tri[3]]
    
    -- Draw triangle with color
    local color = tri.color or {r=255, g=255, b=255, a=255}
    M.drawTriangle(image, v1, v2, v3, color)
  end
  
  return image
end

-- Triangle drawing helper
function M.drawTriangle(image, v1, v2, v3, color)
  local points = {v1, v2, v3}
  
  -- Sort vertices by y coordinate
  table.sort(points, function(a, b) return a[2] < b[2] end)
  
  local x1, y1 = points[1][1], points[1][2]
  local x2, y2 = points[2][1], points[2][2]
  local x3, y3 = points[3][1], points[3][2]
  
  -- Handle flat triangles
  if math.floor(y1) == math.floor(y3) then return end
  
  -- Draw the triangle using two parts
  local colorObj = Color(color.r, color.g, color.b, color.a or 255)
  local colorValue = app.pixelColor.rgba(color.r, color.g, color.b, color.a or 255)
  
  -- Interpolation helpers
  local function interpolate(y, x1, y1, x2, y2)
    if y1 == y2 then return x1 end
    return x1 + (y - y1) * (x2 - x1) / (y2 - y1)
  end
  
  -- Draw scanlines
  for y = math.max(0, math.floor(y1)), math.min(image.height-1, math.floor(y3)) do
    -- Calculate x coordinates
    local xa, xb
    
    -- First part of triangle
    if y <= y2 then
      xa = interpolate(y, x1, y1, x2, y2)
      xb = interpolate(y, x1, y1, x3, y3)
    else
      -- Second part of triangle
      xa = interpolate(y, x2, y2, x3, y3)
      xb = interpolate(y, x1, y1, x3, y3)
    end
    
    -- Ensure left-to-right ordering
    if xa > xb then xa, xb = xb, xa end
    
    -- Draw horizontal line
    for x = math.max(0, math.floor(xa)), math.min(image.width-1, math.floor(xb)) do
      image:putPixel(x, y, colorValue)
    end
  end
end

return M