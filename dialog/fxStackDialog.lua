-- FX Stack dialog (baseline UI). Extend with full module editing as needed.
local fxStackDialog = {}

function fxStackDialog.open(viewParams)
  local dlg = Dialog("FX Stack")
  dlg:label{ text = "Configure shading modules for 'Stack' mode." }
  dlg:newrow()
  -- Future: add module list, add/remove/reorder, per-module controls matching AseVoxel
  dlg:button{ text="Close", onclick=function() dlg:close() end }
  dlg:show{ wait=false }
  return dlg
end

return fxStackDialog