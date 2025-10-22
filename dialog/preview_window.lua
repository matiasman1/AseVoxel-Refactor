-- dialog/preview_window.lua
-- Separate preview window with canvas, mimicking AseVoxel's preview dialog

local preview_utils = require("render.preview_utils")
local state_mod = require("core.state")

local M = {
  _dlg = nil,
  _image = nil,
}

local function drawCentered(ctx, img, w, h)
  if not img then
    ctx:fillText("Rendering...", 8, 20)
    return
  end
  local ox = math.floor((w - img.width)/2)
  local oy = math.floor((h - img.height)/2)
  ctx:drawImage(img, ox, oy)
end

local function requestRender(viewParams)
  preview_utils.openPreview(viewParams, function(res)
    if res and res.image then
      M._image = res.image
      if M._dlg then pcall(function() M._dlg:repaint() end) end
    end
  end)
end

function M.open(viewParams)
  local vp = viewParams or state_mod.default()
  local canvasSize = vp.canvasSize or 300
  local dlg = Dialog("Voxel Preview")
  M._dlg = dlg

  dlg:canvas{
    id="preview", width=canvasSize, height=canvasSize,
    onpaint=function(ev)
      local ctx = ev.context
      drawCentered(ctx, M._image, ev.bounds.width, ev.bounds.height)
    end
  }

  dlg:button{
    text="Close",
    onclick=function() dlg:close(); M._dlg=nil end
  }

  dlg:show{ wait=false }
  requestRender(vp)
end

return M