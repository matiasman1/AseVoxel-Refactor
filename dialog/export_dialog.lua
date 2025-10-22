-- dialog/export_dialog.lua
local logic = require("dialog.utils.export_logic")

local M = {}

local function previewCanvas(dlg, img, w, h)
  dlg:canvas{
    id="preview", width=w, height=h,
    onpaint=function(ev)
      local ctx = ev.context
      if img then
        local ox = (w - img.width)/2
        local oy = (h - img.height)/2
        ctx:drawImage(img, ox, oy)
      else
        ctx:fillText("Loading preview...", w/2 - 50, h/2)
      end
    end
  }
end

function M.open(viewParams, options)
  local sprite = app.activeSprite
  if not sprite then app.alert("No sprite!") return end
  local dlg = Dialog("Export Voxel Model")
  local st = logic.initState(viewParams)
  local canvasW, canvasH = 160, 160
  local previewImage, voxels = logic.computePreview(sprite, viewParams, canvasW, canvasH)

  previewCanvas(dlg, previewImage, canvasW, canvasH)
  dlg:label{ text="Model Information:" }; dlg:newrow()
  dlg:label{ id="voxCount", text = voxels and ("Voxel count: "..#voxels) or "Voxel count: (No voxels found)" }
  dlg:newrow()
  dlg:label{ id="dims", text = "" }
  dlg:separator{ text="Export Format" }
  dlg:combobox{
    id="format", label="Format:", options={"obj","ply","stl"}, option=st.opts.format,
    onchange=function() st.opts.format = dlg.data.format end
  }
  dlg:check{
    id="includeTexture", label="Include Material:", selected=st.opts.includeTexture,
    onchange=function() st.opts.includeTexture = dlg.data.includeTexture end
  }
  dlg:separator{ text="Model Options" }
  dlg:number{
    id="scaleModel", label="Scale:", text=tostring(st.opts.scaleModel), decimals=2,
    onchange=function() st.opts.scaleModel = dlg.data.scaleModel end
  }
  dlg:check{
    id="usePixelScale", label="Use Pixel Scale", selected=(st.opts.exportAtScale ~= nil),
    onchange=function()
      st.opts.exportAtScale = dlg.data.usePixelScale and (viewParams.scaleLevel or 1.0) or nil
      local eff = st.opts.exportAtScale or st.opts.scaleModel
      dlg:modify{ id="scaleInfo", text=string.format("Effective scale: %.0f%% (%.2f units per voxel)", (eff or 1.0)*100, (eff or 1.0)) }
    end
  }
  dlg:label{
    id="scaleInfo",
    text=string.format("Effective scale: %.0f%% (%.2f units per voxel)", (viewParams.scaleLevel or 1.0)*100, (viewParams.scaleLevel or 1.0))
  }
  dlg:check{
    id="optimizeMesh", label="Optimize Mesh", selected=st.opts.optimizeMesh,
    onchange=function() st.opts.optimizeMesh = dlg.data.optimizeMesh end
  }
  dlg:separator{ text="Outline Options" }
  dlg:check{ id="enableOutlines", label="Enable Outlines", selected=false, onchange=function() st.opts.enableOutlines = dlg.data.enableOutlines end }
  dlg:color{ id="outlineColor", label="Outline Color:", color=Color(0,0,0), onchange=function() st.opts.outlineColor = dlg.data.outlineColor end }
  dlg:slider{ id="outlineWidth", label="Outline Width:", min=1, max=3, value=1, onchange=function() st.opts.outlineWidth = dlg.data.outlineWidth end }
  dlg:separator{ text="Export Location" }
  local defaultPath = app.fs.filePath(sprite.filename or "") or ""
  dlg:entry{ id="filename", label="Filename:", text=st.filename, focus=true }
  dlg:separator()
  dlg:button{
    text="Export", focus=true,
    onclick=function()
      if not voxels or #voxels == 0 then app.alert("No voxels to export!"); return end
      local path = logic.resolvePath(defaultPath, dlg.data.filename, st.opts.format)
      local ok = logic.export(voxels, path, st.opts)
      app.alert(ok and ("3D model exported successfully:\n"..path) or "Failed to export 3D model!")
      if ok then dlg:close() end
    end
  }
  dlg:button{ text="Cancel", onclick=function() dlg:close() end }
  dlg:show{ wait=false }
end

return M