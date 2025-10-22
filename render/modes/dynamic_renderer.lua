-- render/modes/dynamic_renderer.lua
-- Dynamic lighting renderer implementation

local mathUtils = require("utils.math_utils")
local dynLight = require("render.local.dynamic_lighting")
local debug = require("core.debug")
local nativeBridge = require("core.native_bridge")

local M = {}

function M.renderVoxelModel(voxelModel, params)
  -- Try to use native renderer if available and not forced off
  if nativeBridge.isAvailable() and not params.forceNoNative then
    local result = nativeBridge.renderDynamic(voxelModel, params)
    if result then 
      debug.log("Used native dynamic renderer")
      return result 
    end
  end
  
  -- Fall back to local renderer
  debug.log("Using local dynamic renderer")
  local localRenderer = require("render.local.entry")
  
  -- Ensure we have lighting parameters
  if not params.lighting then
    params.lighting = {
      yaw = 0,
      pitch = 45,
      ambient = 30,
      diffuse = 70,
      lightColor = Color(255, 255, 255)
    }
  end
  
  -- Modify parameters for dynamic rendering
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
    shadingMode = "Dynamic",
    fxStack = nil, -- Don't use FX stack for dynamic mode
    lighting = params.lighting
  }
  
  return localRenderer.renderVoxelModel(voxelModel, renderParams)
end

return M