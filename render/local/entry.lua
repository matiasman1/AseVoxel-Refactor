-- Entry point: orchestrates local rendering using modular helpers

local C = require("render.local.constants")
local modelx = require("render.local.model_extraction")
local cam = require("render.local.camera")
local rast = require("render.local.raster")
local outline = require("render.local.outline")
local export_obj = require("render.local.export_obj")

local M = {}

local function transformCube(rotM, mp, v, scale)
  local out = {}
  for i=1,#C.UNIT_CUBE_VERTICES do
    local p = C.UNIT_CUBE_VERTICES[i]
    local px = v.x + p[1]*scale; local py = v.y + p[2]*scale; local pz = v.z + p[3]*scale
    out[i] = cam.rotatePoint(rotM, mp, {px,py,pz})
  end
  return out
end

local function projectCube(camera, verts)
  local sv = {}
  for i=1,#verts do
    local x,y,z = cam.project(camera, verts[i])
    sv[i] = {x,y,z}
  end
  return sv
end

local function renderImage(model, params, width, height)
  local img = Image(width, height, ColorMode.RGB)
  local mp = modelx.calculateMiddlePoint(model)
  local rotM = cam.rotationMatrix(params)
  local camera = cam.build(mp._bounds, mp, params, width, height, params.scaleLevel or 1.0)
  for _,vox in ipairs(model) do
    local base = vox.color or {r=255,g=255,b=255,a=255}
    local world = transformCube(rotM, mp, vox, params.scaleLevel or 1.0)
    local screen = projectCube(camera, world)
    rast.drawVoxel(img, screen, rotM, base, params)
  end
  return img
end

function M.generateVoxelModel(sprite)
  return modelx.generateVoxelModel(sprite)
end

function M.calculateModelBounds(model)
  return modelx.calculateModelBounds(model)
end

function M.calculateMiddlePoint(model)
  return modelx.calculateMiddlePoint(model)
end

function M.renderVoxelModel(model, params)
  local w = (params and params.width) or (params.canvasSize or 200)
  local h = (params and params.height) or (params.canvasSize or 200)
  local img = renderImage(model, params or {}, w, h)
  if params and params.enableOutline and params.outlineSettings then
    img = outline.applyOutline(img, params.outlineSettings)
  end
  return img
end

function M.exportOBJ(voxels, path, options)
  return export_obj.exportOBJ(voxels, path, options)
end

return M