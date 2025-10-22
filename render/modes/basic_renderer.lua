-- render/modes/basic_renderer.lua
-- Basic rendering mode implementation

local mathUtils = require("utils.math_utils")
local rotation = require("core.rotation")
local debug = require("core.debug")
local nativeBridge = require("core.native_bridge")
local constants = require("render.local.constants")

local M = {}

-- Apply basic shading based on face direction
local function shadeFace(faceColor, faceName, rotationMatrix)
  local factors = {
    top = 1.0,    -- Full brightness for top faces
    bottom = 0.4, -- Darkest for bottom faces
    front = 0.9,  -- Almost full brightness for front faces
    back = 0.6,   -- Darker for back faces
    left = 0.7,   -- Medium dark for left faces
    right = 0.8   -- Medium bright for right faces
  }
  
  local factor = factors[faceName] or 0.8
  
  -- Create a new color with adjusted brightness
  return {
    r = math.floor(faceColor.r * factor),
    g = math.floor(faceColor.g * factor),
    b = math.floor(faceColor.b * factor),
    a = faceColor.a or 255
  }
end

-- Get face visibility based on face normal and view direction
local function getFaceVisibility(faceName, rotationMatrix)
  -- Face normals in model space
  local faceNormals = {
    top = {0, 1, 0},
    bottom = {0, -1, 0},
    front = {0, 0, 1},
    back = {0, 0, -1},
    left = {-1, 0, 0},
    right = {1, 0, 0}
  }
  
  local normal = faceNormals[faceName]
  if not normal then return false end
  
  -- Transform normal by rotation matrix
  local nx = rotationMatrix[1][1] * normal[1] + rotationMatrix[1][2] * normal[2] + rotationMatrix[1][3] * normal[3]
  local ny = rotationMatrix[2][1] * normal[1] + rotationMatrix[2][2] * normal[2] + rotationMatrix[2][3] * normal[3]
  local nz = rotationMatrix[3][1] * normal[1] + rotationMatrix[3][2] * normal[2] + rotationMatrix[3][3] * normal[3]
  
  -- Check if normal faces camera (positive Z in view space)
  return nz < 0
end

function M.renderVoxelModel(voxelModel, params)
  -- Try to use native renderer if available and not forced off
  if nativeBridge.isAvailable() and not params.forceNoNative then
    local result = nativeBridge.renderBasic(voxelModel, params)
    if result then 
      debug.log("Used native basic renderer")
      return result 
    end
  end
  
  -- Fall back to local renderer
  debug.log("Using local basic renderer")
  local localRenderer = require("render.local.entry")
  
  -- Modify parameters for basic rendering
  local renderParams = {
    x = params.xRotation,
    y = params.yRotation,
    z = params.zRotation,
    rotationMatrix = params.rotationMatrix,
    orthogonal = params.orthogonal or params.orthogonalView,
    scaleLevel = params.scaleLevel,
    pixelSize = params.pixelSize or 1,
    canvasSize = params.canvasSize or 200,
    width = params.width or params.canvasSize or 200,
    height = params.height or params.canvasSize or 200,
    shadingMode = "Basic",
    fxStack = nil, -- Don't use FX stack for basic mode
    shadeFunc = shadeFace,
    visibilityFunc = getFaceVisibility
  }
  
  return localRenderer.renderVoxelModel(voxelModel, renderParams)
end

return M