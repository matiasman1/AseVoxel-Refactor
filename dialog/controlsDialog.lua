-- Controls dialog: expanded to mirror AseVoxel controls
local dialogueManager = require("dialog.dialogueManager")
local viewerCore = require("core.viewerCore")

local controlsDialog = {}

local function applyAndUpdate(previewDlg, viewParams)
  dialogueManager.safeUpdate(viewParams, function()
    viewerCore.updatePreviewCanvas(previewDlg, viewParams)
    if dialogueManager.controlsDialog then
      pcall(function()
        dialogueManager.controlsDialog:modify{
          id="scaleLabel",
          text="Scale: " .. string.format("%.0f%%", (viewParams.scaleLevel or 1)*100)
        }
      end)
    end
  end)
end

function controlsDialog.open(viewParams, previewDlg)
  local vp = {}
  for k,v in pairs(viewParams or {}) do vp[k] = v end

  local dlg = Dialog("AseVoxel - Controls")

  dlg:label{ id="scaleLabel", text="Scale: " .. string.format("%.0f%%", (vp.scaleLevel or 1)*100) }
  dlg:newrow()

  dlg:combobox{
    id="shadingMode", label="Shading",
    options={"Stack","Basic","Dynamic"},
    option=vp.shadingMode or "Stack",
    onchange=function()
      vp.shadingMode = dlg.data.shadingMode
      applyAndUpdate(previewDlg, vp)
    end
  }

  dlg:check{
    id="orthogonal", text="Orthographic",
    selected=vp.orthogonalView or false,
    onclick=function()
      vp.orthogonalView = dlg.data.orthogonal
      applyAndUpdate(previewDlg, vp)
    end
  }

  dlg:slider{
    id="depth", label="Depth", min=0, max=100, value=vp.depthPerspective or 50,
    onchange=function()
      vp.depthPerspective = dlg.data.depth
      vp.fovDegrees = 5 + (75-5)*(vp.depthPerspective/100)
      applyAndUpdate(previewDlg, vp)
    end
  }

  dlg:slider{
    id="scale", label="Scale", min=10, max=400, value=(vp.scaleLevel or 1)*100,
    onchange=function()
      local v = dlg.data.scale
      vp.scaleLevel = math.max(0.1, v/100.0)
      applyAndUpdate(previewDlg, vp)
    end
  }

  dlg:separator()
  dlg:slider{
    id="xRot", label="X", min=0, max=360, value=vp.xRotation or 315,
    onchange=function() vp.xRotation = dlg.data.xRot; applyAndUpdate(previewDlg, vp) end
  }
  dlg:slider{
    id="yRot", label="Y", min=0, max=360, value=vp.yRotation or 324,
    onchange=function() vp.yRotation = dlg.data.yRot; applyAndUpdate(previewDlg, vp) end
  }
  dlg:slider{
    id="zRot", label="Z", min=0, max=360, value=vp.zRotation or 29,
    onchange=function() vp.zRotation = dlg.data.zRot; applyAndUpdate(previewDlg, vp) end
  }

  dlg:separator()
  dlg:button{ id="helpBtn", text="Help", onclick=function() dialogueManager.openHelpDialog() end }
  dlg:button{ id="fxBtn", text="FX Stack", onclick=function() require("dialog.fxStackDialog").open(vp) end }
  dlg:button{
    id="closeButton", text="Close",
    onclick=function() dialogueManager.controlsDialog = nil; dlg:close() end
  }

  dlg:show{ wait=false }
  return dlg
end

return controlsDialog