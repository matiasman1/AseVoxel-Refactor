-- render/modes/stack_renderer.lua
-- FX Stack-based renderer implementation

local mathUtils = require("utils.math_utils")
local fxStack = require("render.fx_stack")
local debug = require("core.debug")
local nativeBridge = require("core.native_bridge")

local M = {}

function M.renderVoxelModel(voxelModel, params)
  -- Try to use native renderer if available and not forced off
  if nativeBridge.isAvailable() and not params.forceNoNative then
    local result = nativeBridge.renderStack(voxelModel, params)
    if result then 
      debug.log("Used native stack renderer")
      return result 
    end
  end
  
  -- Fall back to local renderer
  debug.log("Using local stack renderer")
  local localRenderer = require("render.local.entry")
  
  -- Ensure we have an FX stack
  if not params.fxStack then
    params.fxStack = fxStack.makeDefaultStack()
  end
  
  -- Use local renderer with FX stack
  return localRenderer.renderVoxelModel(voxelModel, params)
end

return M