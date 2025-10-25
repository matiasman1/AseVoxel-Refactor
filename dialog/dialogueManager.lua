-- Dialog manager: holds state, routes to per-dialog modules, throttles updates
local mathUtils = require("mathUtils")

local dialogueManager = {
  controlsDialog = nil,
  previewDialog = nil,
  exportDialog = nil,
  mainDialog = nil,

  currentRotationMatrix = mathUtils.identity(),

  isUpdatingControls = false,
  updateLock = false,
  lastUpdateTime = 0,
  updateThrottleMs = 0
}

function dialogueManager.safeUpdate(viewParams, updateCallback)
  local t = os.clock() * 1000
  if dialogueManager.updateLock then return end
  if dialogueManager.updateThrottleMs > 0 and (t - dialogueManager.lastUpdateTime) < dialogueManager.updateThrottleMs then
    return
  end
  dialogueManager.updateLock = true
  dialogueManager.lastUpdateTime = t
  local ok, err = pcall(function() updateCallback(viewParams) end)
  dialogueManager.updateLock = false
  if not ok then
    print("safeUpdate error: " .. tostring(err))
  end
end

function dialogueManager.openPreviewDialog(viewParams)
  local previewDialog = require("previewDialog")
  dialogueManager.previewDialog = previewDialog.open(viewParams)
  return dialogueManager.previewDialog
end

function dialogueManager.openControlsDialog(viewParams, previewDialog)
  local controlsDialog = require("controlsDialog")
  dialogueManager.controlsDialog = controlsDialog.open(viewParams, previewDialog)
  return dialogueManager.controlsDialog
end

function dialogueManager.openHelpDialog()
  local help = require("helpDialog")
  return help.open()
end

function dialogueManager.openAnimationDialog(viewParams, modelDimensions, voxelModel, canvasSize, scaleLevel)
  local anim = require("animationDialog")
  return anim.open(viewParams, modelDimensions, voxelModel, canvasSize, scaleLevel)
end

function dialogueManager.openExportDialog()
  local exp = require("exportDialog")
  dialogueManager.exportDialog = exp.open()
  return dialogueManager.exportDialog
end

function dialogueManager.closeAll()
  local function close(dlgRefField)
    local dlg = dialogueManager[dlgRefField]
    if dlg then
      pcall(function() dlg:close() end)
      dialogueManager[dlgRefField] = nil
    end
  end
  close("controlsDialog")
  close("previewDialog")
  close("exportDialog")
  close("mainDialog")
end

return dialogueManager