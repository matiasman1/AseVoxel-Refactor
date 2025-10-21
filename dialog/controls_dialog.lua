-- dialog/controls_dialog.lua
-- Single exported open() that composes UI and binds to logic

local logic = require("dialog.utils.controls_logic")
local preview = require("render.preview_utils")

local M = {}

local function bindEuler(dlg, vp, onChange)
  dlg:slider{ id="eulerX", label="X", min=0, max=359, value=vp.xRotation,
    onchange=function() onChange(logic.applyEuler(vp, dlg.data.eulerX, nil, nil)) end }
  dlg:slider{ id="eulerY", label="Y", min=0, max=359, value=vp.yRotation,
    onchange=function() onChange(logic.applyEuler(vp, nil, dlg.data.eulerY, nil)) end }
  dlg:slider{ id="eulerZ", label="Z", min=0, max=359, value=vp.zRotation,
    onchange=function() onChange(logic.applyEuler(vp, nil, nil, dlg.data.eulerZ)) end }
end

local function bindProjection(dlg, vp, onChange)
  dlg:check{ id="orthogonal", label="Orthographic", selected=vp.orthogonalView,
    onchange=function() onChange(logic.applyProjection(vp, dlg.data.orthogonal, vp.perspectiveScaleRef)) end }
  dlg:combobox{ id="psref", label="Perspective Ref", options={"near","middle","far"}, option=vp.perspectiveScaleRef,
    onchange=function() onChange(logic.applyProjection(vp, vp.orthogonalView, dlg.data.psref)) end }
end

local function bindScale(dlg, vp, onChange)
  dlg:slider{ id="scale", label="Scale", min=0.05, max=8.0, value=vp.scaleLevel,
    onchange=function() onChange(logic.applyScale(vp, dlg.data.scale)) end }
end

function M.open(viewParams, handlers)
  local vp = logic.initParams(viewParams)
  local dlg = Dialog("View Controls")
  local function onChange(newVp)
    preview.queuePreview(newVp, "controls")
    if handlers and handlers.onChange then handlers.onChange(newVp) end
  end
  bindEuler(dlg, vp, onChange)
  dlg:separator()
  bindProjection(dlg, vp, onChange)
  dlg:separator()
  bindScale(dlg, vp, onChange)
  dlg:button{ text="Help", onclick=function() if handlers and handlers.onHelp then handlers.onHelp() end end }
  dlg:button{ text="Close", onclick=function() dlg:close() end, focus=true }
  dlg:show{ wait=false }
  return dlg
end

return M