-- Shared dialog helpers (kept minimal to avoid duplication)
local dialogUtils = {}

function dialogUtils.addHeader(dlg, text)
  dlg:label{ text = text }
  dlg:newrow()
end

function dialogUtils.addSpacer(dlg)
  dlg:label{ text = "" }
  dlg:newrow()
end

return dialogUtils