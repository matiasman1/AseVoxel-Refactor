-- dialog/utils/export_logic.lua
local file_utils = require("utils.file_utils")
local previewRenderer = require("previewRenderer")
local debug = require("core.debug")

local M = {}

local function defaultOptions()
  return {
    format="obj",
    includeTexture=true,
    scaleModel=1.0,
    optimizeMesh=true,
    exportAtScale=nil,         -- when true, use current pixel scale from viewParams
    enableOutlines=false,
    outlineColor=Color(0,0,0),
    outlineWidth=1
  }
end

function M.initState(viewParams)
  debug.log("export_logic.initState")
  return {
    opts = defaultOptions(),
    path = "",
    filename = "model.obj",
    scaleInfo = string.format("Effective scale: %.0f%% (%.2f units per voxel)",
                              (viewParams.scaleLevel or 1.0)*100, viewParams.scaleLevel or 1.0)
  }
end

function M.computePreview(sprite, viewParams, canvasW, canvasH)
  debug.log("export_logic.computePreview")
  local vox = previewRenderer.generateVoxelModel(sprite)
  if not vox or #vox == 0 then return nil, vox end
  local params = {
    x=315, y=324, z=29, orthogonal=true, scale=3.0, shadingMode="Stack",
    fxStack=viewParams.fxStack, pixelSize=1, canvasSize=canvasW, zoomFactor=0.25
  }
  local img = previewRenderer.renderVoxelModel(vox, params)
  return img, vox
end

function M.resolvePath(defaultPath, filename, format)
  local name = filename
  if not name:match("%.%w+$") then name = name .. "." .. (format or "obj") end
  local absolute = (name:sub(1,1) == "/" or name:sub(1,1) == "\\" or (name:len()>1 and name:sub(2,2) == ":"))
  return absolute and name or app.fs.joinPath(defaultPath or "", name)
end

function M.export(voxelModel, path, opts)
  if opts.format == "obj" then
    return previewRenderer.exportOBJ(voxelModel, path, opts)
  else
    return require("utils.file_utils").exportGeneric(voxelModel, path, opts)
  end
end

return M