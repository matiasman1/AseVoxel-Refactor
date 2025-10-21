-- dialog/utils/outline_logic.lua
-- Pure helpers for outline dialog

local debug = require("core.debug")
local M = {}

local function sanitizeMode(mode)
  if mode == "Voxels (Slow)" then return "voxels" end
  return "model"
end

function M.createSettings(data)
  debug.log("outline_logic.createSettings")
  return {
    mode = sanitizeMode(data.outlineMode),
    place = data.place or "outside",
    matrix = data.matrix or "circle",
    color = data.color or Color(0,0,0)
  }
end

function M.applyToViewParams(vp, settings)
  vp.outlineSettings = settings
  vp.enableOutline = true
  return vp
end

return M