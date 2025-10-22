-- render/modes/rainbow_renderer.lua
-- Rainbow rendering mode (for fun)

local mathUtils = require("utils.math_utils")
local debug = require("core.debug")

local M = {}

-- Generate a rainbow color based on voxel position
local function rainbowColor(voxel, time)
  if not time then time = os.clock() * 0.5 end
  
  local h = (voxel.x * 0.1 + voxel.y * 0.2 + voxel.z * 0.3 + time) % 1
  local s = 0.8
  local v = 0.9
  
  -- HSV to RGB conversion
  local hi = math.floor(h * 6) % 6
  local f = h * 6 - hi
  local p = v * (1 - s)
  local q = v * (1 - f * s)
  local t = v * (1 - (1 - f) * s)
  
  local r, g, b
  
  if hi == 0 then r, g, b = v, t, p
  elseif hi == 1 then r, g, b = q, v, p
  elseif hi == 2 then r, g, b = p, v, t
  elseif hi == 3 then r, g, b = p, q, v
  elseif hi == 4 then r, g, b = t, p, v
  else r, g, b = v, p, q end
  
  -- Convert to 0-255 range
  return {
    r = math.floor(r * 255),
    g = math.floor(g * 255),
    b = math.floor(b * 255),
    a = 255
  }
end

function M.renderVoxelModel(voxelModel, params)
  debug.log("Using rainbow renderer")
  
  -- Create rainbow-colored voxels
  local coloredVoxels = {}
  local time = os.clock() * 0.5
  
  for i, voxel in ipairs(voxelModel) do
    local newVoxel = {
      x = voxel.x,
      y = voxel.y,
      z = voxel.z,
      color = rainbowColor(voxel, time)
    }
    table.insert(coloredVoxels, newVoxel)
  end
  
  -- Use stack renderer as base
  local stackRenderer = require("render.modes.stack_renderer")
  return stackRenderer.renderVoxelModel(coloredVoxels, params)
end

return M