-- dialog/utils/controls_logic.lua
-- Pure logic for controls dialog (no dlg: calls)

local math_utils = require("utils.math_utils")

local M = {}

local function clampAngle(a) return (a % 360 + 360) % 360 end

function M.initParams(vp)
  vp.xRotation = clampAngle(vp.xRotation or 315)
  vp.yRotation = clampAngle(vp.yRotation or 324)
  vp.zRotation = clampAngle(vp.zRotation or 29)
  vp.scaleLevel = vp.scaleLevel or 1.0
  vp.orthogonalView = vp.orthogonalView or false
  vp.perspectiveScaleRef = vp.perspectiveScaleRef or "middle"
  return vp
end

function M.applyEuler(vp, x, y, z)
  vp.xRotation = clampAngle(x or vp.xRotation)
  vp.yRotation = clampAngle(y or vp.yRotation)
  vp.zRotation = clampAngle(z or vp.zRotation)
  vp.rotationMatrix = math_utils.createRotationMatrix(vp.xRotation, vp.yRotation, vp.zRotation)
  return vp
end

function M.applyScale(vp, s)
  vp.scaleLevel = math.max(0.05, math.min(8.0, s or vp.scaleLevel))
  return vp
end

function M.applyProjection(vp, orthogonal, ref)
  vp.orthogonalView = not not orthogonal
  vp.perspectiveScaleRef = ref or vp.perspectiveScaleRef
  return vp
end

return M