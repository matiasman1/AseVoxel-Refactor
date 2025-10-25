-- fxStackDialog: configure FX stack modules (simplified parity stub)
local fxStackDialog = {}

function fxStackDialog.open(viewParams)
  local dlg = Dialog("FX Stack")
  dlg:label{ text = "Configure shading modules for 'Stack' mode." }
  dlg:newrow()
  dlg:button{ text="Close", onclick=function() dlg:close() end }
  dlg:show{ wait=false }
  return dlg
end

return fxStackDialog