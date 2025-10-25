-- Thin orchestration for opening the viewer dialogs
local dialogueManager = require("dialog.dialogueManager")
local viewerCore = require("core.viewerCore")

local modelViewer = {}

-- Shared default view params (kept compatible with original)
local defaultViewParams = {
  xRotation = 315, yRotation = 324, zRotation = 29,
  eulerX = 315, eulerY = 324, eulerZ = 29,
  depthPerspective = 50,
  fovDegrees = nil,
  orthogonalView = false,
  scaleLevel = 1.0,
  canvasSize = 200,
  shadingMode = "Stack",
  fxStack = nil
}

function modelViewer.openModelViewer()
  -- Close any existing instances
  dialogueManager.closeAll()

  -- Open preview first so controls can reference it
  local previewDlg = dialogueManager.openPreviewDialog(defaultViewParams)
  local controlsDlg = dialogueManager.openControlsDialog(defaultViewParams, previewDlg)

  dialogueManager.previewDialog = previewDlg
  dialogueManager.controlsDialog = controlsDlg
end

return modelViewer