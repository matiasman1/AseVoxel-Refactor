-- dialog/outline_dialog.lua
-- UI only; delegates to outline_logic

local logic = require("dialog.utils.outline_logic")

local M = {}

function M.open(viewParams, updateCallback)
  local dlg = Dialog("Outline Settings")
  dlg:combobox{
    id = "outlineMode", label="Outline Mode:",
    options={"Model (Fast)", "Voxels (Slow)"},
    option = (viewParams.outlineSettings and viewParams.outlineSettings.mode == "voxels") and "Voxels (Slow)" or "Model (Fast)"
  }
  dlg:combobox{
    id = "place", label="Position:",
    options={"inside","outside","center"},
    option=(viewParams.outlineSettings and viewParams.outlineSettings.place) or "outside"
  }
  dlg:combobox{
    id = "matrix", label="Shape:",
    options={"circle","square","horizontal","vertical"},
    option=(viewParams.outlineSettings and viewParams.outlineSettings.matrix) or "circle"
  }
  dlg:color{
    id="color", label="Color:",
    color=(viewParams.outlineSettings and viewParams.outlineSettings.color) or Color(0,0,0)
  }
  dlg:button{
    text="OK", focus=true,
    onclick=function()
      local s = logic.createSettings(dlg.data)
      logic.applyToViewParams(viewParams, s)
      if updateCallback then updateCallback() end
      dlg:close()
    end
  }
  dlg:button{ text="Cancel", onclick=function() dlg:close() end }
  dlg:show{ wait=true }
end

return M