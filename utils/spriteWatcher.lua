-- spriteWatcher: auto-refresh preview when sprite changes
local viewerCore = require("core.viewerCore")
local dialogueManager = require("dialog.dialogueManager")

local spriteWatcher = {}
spriteWatcher._enabled = false
spriteWatcher._lastChangeId = 0

local function getChangeId(sprite)
  if not sprite then return 0 end
  -- naive change id using sprite hash: size + frame count + layer count
  local n = (sprite.width or 0) * 73856093 + (sprite.height or 0) * 19349663
  n = n + (#sprite.layers) * 83492791 + (#sprite.frames) * 2654435761
  return n
end

function spriteWatcher.enable(v) spriteWatcher._enabled = v and true or false end

function spriteWatcher.tick(viewParams)
  if not spriteWatcher._enabled then return end
  local sprite = app.activeSprite
  if not sprite then return end
  local cid = getChangeId(sprite)
  if cid ~= spriteWatcher._lastChangeId then
    spriteWatcher._lastChangeId = cid
    if dialogueManager.previewDialog then
      viewerCore.updatePreviewCanvas(dialogueManager.previewDialog, viewParams)
    end
  end
end

return spriteWatcher