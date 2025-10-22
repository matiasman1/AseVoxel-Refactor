-- render/renderer_factory.lua
-- Factory for selecting appropriate renderer based on mode

local debug = require("core.debug")

local M = {}

-- Map mode name to renderer module
local rendererMap = {
  None = "render.modes.basic_renderer",    -- Basic with no shading
  Basic = "render.modes.basic_renderer",
  Stack = "render.modes.stack_renderer",
  Dynamic = "render.modes.dynamic_renderer",
  Mesh = "render.modes.mesh_renderer",
  Native = nil,  -- Special case handled below
  Rainbow = "render.modes.rainbow_renderer"
}

-- Get appropriate renderer based on mode and parameters
function M.getRenderer(mode, params)
  -- Check for Native mode (special case)
  if mode == "Native" then
    local nativeBridge = require("core.native_bridge")
    if nativeBridge.isAvailable() then
      debug.log("Using native renderer directly")
      return nativeBridge
    else
      debug.log("Native renderer not available, falling back to Stack")
      mode = "Stack"
    end
  end
  
  -- Get renderer module path
  local rendererPath = rendererMap[mode] or rendererMap.Stack
  
  -- Load renderer module
  local ok, renderer = pcall(require, rendererPath)
  if not ok then
    debug.log("Failed to load renderer for mode " .. mode .. ": " .. tostring(renderer))
    -- Fall back to basic renderer
    return require("render.modes.basic_renderer")
  end
  
  debug.log("Using renderer for mode: " .. mode)
  return renderer
end

-- Render a model with the appropriate renderer
function M.renderVoxelModel(voxelModel, params)
  local mode = params.shadingMode or "Stack"
  local renderer = M.getRenderer(mode, params)
  
  local result = renderer.renderVoxelModel(voxelModel, params)
  
  -- Apply outline if enabled
  if result and params.enableOutline and params.outlineSettings then
    local outline = require("render.local.outline")
    result = outline.applyOutline(result, params.outlineSettings)
  end
  
  return result
end

return M