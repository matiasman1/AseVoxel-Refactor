-- Preview window split out from original modelViewer/dialogueManager responsibilities
local viewerCore = require("core.viewerCore")

local previewDialog = {}

function previewDialog.open(viewParams)
  local vp = {}
  for k,v in pairs(viewParams or {}) do vp[k] = v end
  local previewImage = nil

  local dlg = Dialog("AseVoxel - Preview")

  local canvasSize = vp.canvasSize or 200
  dlg:canvas{
    id="previewCanvas",
    width = canvasSize, height = canvasSize,
    onpaint = function(ev)
      local ctx = ev.context
      if not previewImage then
        previewImage = viewerCore.renderPreview(vp)
      end
      if previewImage then
        local ox = math.floor((canvasSize - previewImage.width)/2)
        local oy = math.floor((canvasSize - previewImage.height)/2)
        ctx:drawImage(previewImage, ox, oy)
      end
    end
  }

  dlg:show{ wait=false }
  return dlg
end

return previewDialog