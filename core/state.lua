-- core/state.lua
-- Enhanced state management with support for all rendering modes

local mathUtils = require("utils.math_utils")

local M = {}

function M.default()
  return {
    -- Rotation and position
    xRotation = 315, 
    yRotation = 324, 
    zRotation = 29,
    rotationMatrix = mathUtils.createRotationMatrix(315, 324, 29),
    
    -- Scale and view
    scaleLevel = 1.0,
    canvasSize = 300,
    
    -- Rendering modes
    shadingMode = "Stack",
    useMesh = false,
    useNative = true,
    
    -- Projection
    orthogonalView = false,
    perspectiveScaleRef = "middle",
    fovDegrees = 45,
    
    -- FX and effects
    fxStack = nil,
    enableOutline = false,
    outlineSettings = nil,
    
    -- Lighting
    lighting = {
      yaw = 0,
      pitch = 45,
      ambient = 30,
      diffuse = 70,
      lightColor = Color(255, 255, 255),
      showCone = false
    },
    
    -- Layer scroll
    layerScrollMode = false,
    layerScrollMin = 0,
    layerScrollMax = 999
  }
end

function M.updateRotation(vp, x, y, z)
  if x ~= nil then vp.xRotation = x % 360 end
  if y ~= nil then vp.yRotation = y % 360 end
  if z ~= nil then vp.zRotation = z % 360 end
  vp.rotationMatrix = mathUtils.createRotationMatrix(vp.xRotation, vp.yRotation, vp.zRotation)
end