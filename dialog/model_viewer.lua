-- dialog/model_viewer.lua
-- Main dialog for the model viewer

local preview_utils = require("render.preview_utils")
local math_utils = require("utils.math_utils")
local color_utils = require("utils.color_utils")
local controls_dialog = require("dialog.controls_dialog")
local animation_dialog = require("dialog.animation_dialog") 
local export_dialog = require("dialog.export_dialog")
local outline_dialog = require("dialog.outline_dialog")
local fxstack_dialog = require("dialog.fxstack_dialog")
local help_dialog = require("dialog.help_dialog")
local debug = require("core.debug")

local M = {}
M.mainDialog = nil
M.previewDialog = nil
M.previewImage = nil
M.voxelModel = nil
M.modelDimensions = nil

-- Calculate background size based on model dimensions
local function calculateBackgroundSize(dimensions)
  local maxDim = math.max(dimensions.sizeX, dimensions.sizeY, dimensions.sizeZ)
  local size = math.max(150, math.floor(maxDim * 8))
  return size
end

local function applyRenderResult(result, state, resetPan)
  if not result or not result.image then return end
  
  M.previewImage = result.image
  M.voxelModel = result.model
  M.modelDimensions = result.dimensions
  
  -- Update canvas
  if M.previewDialog then
    M.previewDialog:modify{id="preview", width=result.image.width, height=result.image.height}
    M.previewDialog:repaint()
  end
  
  -- Update model info display
  if M.mainDialog and M.voxelModel then
    M.mainDialog:modify{
      id="modelInfo",
      text="Voxel count: " .. #M.voxelModel .. 
           "\nModel size: " .. M.modelDimensions.sizeX .. "×" .. 
           M.modelDimensions.sizeY .. "×" .. M.modelDimensions.sizeZ .. " voxels" ..
           "\nScale: " .. string.format("%.0f%%", (state.scaleLevel or 1.0) * 100)
    }
  end
end

-- Helper: draw single-pixel line on an Image using Bresenham
local function drawLineOnImage(img, x0, y0, x1, y1, color)
  local dx = math.abs(x1 - x0)
  local dy = math.abs(y1 - y0) 
  local sx = x0 < x1 and 1 or -1
  local sy = y0 < y1 and 1 or -1
  local err = dx - dy
  
  while true do
    if x0 >= 0 and y0 >= 0 and x0 < img.width and y0 < img.height then
      img:putPixel(x0, y0, app.pixelColor.rgba(color.red, color.green, color.blue, color.alpha))
    end
    if x0 == x1 and y0 == y1 then break end
    local e2 = 2 * err
    if e2 > -dy then
      err = err - dy
      x0 = x0 + sx
    end
    if e2 < dx then
      err = err + dx
      y0 = y0 + sy
    end
  end
end

local function drawLightConeOverlay(img, viewParams)
  if not viewParams.lighting or not viewParams.lighting.showCone then return img end
  
  local overlayImg = img:clone()
  local lc = viewParams.lighting.lightColor or Color(255, 255, 255)
  local lightCol = { r = lc.red or lc.r or 255, g = lc.green or lc.g or 255, b = lc.blue or lc.b or 255 }
  local color = app.pixelColor.rgba(lightCol.r, lightCol.g, lightCol.b, 150)
  
  -- Calculate light direction
  local yaw = math.rad(viewParams.lighting.yaw or 0)
  local pitch = math.rad(viewParams.lighting.pitch or 0)
  local dirX = math.cos(pitch) * math.sin(yaw)
  local dirY = -math.sin(pitch)
  local dirZ = math.cos(pitch) * math.cos(yaw)
  
  -- Draw from center to edge based on direction
  local cx = img.width / 2
  local cy = img.height / 2
  local length = math.sqrt(img.width * img.width + img.height * img.height) / 2
  local ex = cx + dirX * length
  local ey = cy + dirY * length
  
  drawLineOnImage(overlayImg, math.floor(cx), math.floor(cy), math.floor(ex), math.floor(ey), Color(lightCol.r, lightCol.g, lightCol.b, 200))
  
  return overlayImg
end

local function updateLayerScrollStatusLabel(state, dlg)
  if not dlg then return end
  if not state.layerScrollMode then
    dlg:modify{id="layerScrollStatus", text="Layer scroll: OFF"}
  else
    dlg:modify{id="layerScrollStatus", text=string.format("Layer scroll: %d to %d", state.layerScrollMin or 0, state.layerScrollMax or 999)}
  end
end

function M.requestRender(state, source)
  preview_utils.queuePreview(state, source or "direct", function(result)
    applyRenderResult(result, state)
    if result and result.image and state.lighting and state.lighting.showCone then
      local overlay = drawLightConeOverlay(result.image, state)
      M.previewImage = overlay
      M.previewDialog:repaint()
    end
  end)
end

function M.open(state)
  local mainDlg = Dialog("AseVoxel Model Viewer")
  M.mainDialog = mainDlg
  
  -- Create the preview dialog
  local previewDlg = Dialog("3D Preview")
  M.previewDialog = previewDlg
  
  -- Add UI components
  mainDlg:separator{text="Model Controls"}
  
  -- Row of rotation buttons
  mainDlg:button{
    id="rotX+", text="X+", onclick=function()
      state.xRotation = (state.xRotation + 15) % 360
      state.rotationMatrix = math_utils.createRotationMatrix(state.xRotation, state.yRotation, state.zRotation)
      M.requestRender(state)
    end
  }
  mainDlg:button{
    id="rotX-", text="X-", onclick=function()
      state.xRotation = (state.xRotation - 15) % 360
      state.rotationMatrix = math_utils.createRotationMatrix(state.xRotation, state.yRotation, state.zRotation)
      M.requestRender(state)
    end
  }
  mainDlg:button{
    id="rotY+", text="Y+", onclick=function()
      state.yRotation = (state.yRotation + 15) % 360
      state.rotationMatrix = math_utils.createRotationMatrix(state.xRotation, state.yRotation, state.zRotation)
      M.requestRender(state)
    end
  }
  mainDlg:button{
    id="rotY-", text="Y-", onclick=function()
      state.yRotation = (state.yRotation - 15) % 360
      state.rotationMatrix = math_utils.createRotationMatrix(state.xRotation, state.yRotation, state.zRotation)
      M.requestRender(state)
    end
  }
  mainDlg:button{
    id="rotZ+", text="Z+", onclick=function()
      state.zRotation = (state.zRotation + 15) % 360
      state.rotationMatrix = math_utils.createRotationMatrix(state.xRotation, state.yRotation, state.zRotation)
      M.requestRender(state)
    end
  }
  mainDlg:button{
    id="rotZ-", text="Z-", onclick=function()
      state.zRotation = (state.zRotation - 15) % 360
      state.rotationMatrix = math_utils.createRotationMatrix(state.xRotation, state.yRotation, state.zRotation)
      M.requestRender(state)
    end
  }
  
  mainDlg:newrow()
  
  -- Rotation preset buttons
  mainDlg:button{
    id="iso1", text="Iso 1", onclick=function()
      state.xRotation = 315; state.yRotation = 315; state.zRotation = 0
      state.rotationMatrix = math_utils.createRotationMatrix(state.xRotation, state.yRotation, state.zRotation)
      M.requestRender(state)
    end
  }
  mainDlg:button{
    id="iso2", text="Iso 2", onclick=function()
      state.xRotation = 315; state.yRotation = 45; state.zRotation = 0
      state.rotationMatrix = math_utils.createRotationMatrix(state.xRotation, state.yRotation, state.zRotation)
      M.requestRender(state)
    end
  }
  mainDlg:button{
    id="top", text="Top", onclick=function()
      state.xRotation = 0; state.yRotation = 0; state.zRotation = 0
      state.rotationMatrix = math_utils.createRotationMatrix(state.xRotation, state.yRotation, state.zRotation)
      M.requestRender(state)
    end
  }
  mainDlg:button{
    id="front", text="Front", onclick=function()
      state.xRotation = 270; state.yRotation = 0; state.zRotation = 0
      state.rotationMatrix = math_utils.createRotationMatrix(state.xRotation, state.yRotation, state.zRotation)
      M.requestRender(state)
    end
  }
  mainDlg:button{
    id="side", text="Side", onclick=function()
      state.xRotation = 270; state.yRotation = 270; state.zRotation = 0
      state.rotationMatrix = math_utils.createRotationMatrix(state.xRotation, state.yRotation, state.zRotation)
      M.requestRender(state)
    end
  }
  
  -- Rendering options
  mainDlg:separator{text="Rendering Options"}
  
  mainDlg:combobox{
    id="shadingMode",
    label="Shading Mode:",
    options={"None", "Basic", "Stack", "Dynamic", "Mesh", "Native", "Rainbow"},
    option=state.shadingMode or "Stack",
    onchange=function()
      state.shadingMode = mainDlg.data.shadingMode
      M.requestRender(state)
    end
  }
  
  -- Layer scroll mode controls
  mainDlg:separator{text="Layer Scroll Mode"}
  
  mainDlg:check{
    id="layerScrollMode",
    label="Enable",
    selected=state.layerScrollMode or false,
    onclick=function()
      state.layerScrollMode = mainDlg.data.layerScrollMode
      updateLayerScrollStatusLabel(state, mainDlg)
      M.requestRender(state)
    end
  }
  
  mainDlg:number{
    id="layerScrollMin",
    label="Min Layer:",
    text=tostring(state.layerScrollMin or 0),
    decimals=0,
    onchange=function()
      state.layerScrollMin = mainDlg.data.layerScrollMin
      updateLayerScrollStatusLabel(state, mainDlg)
      M.requestRender(state)
    end
  }
  
  mainDlg:number{
    id="layerScrollMax",
    label="Max Layer:",
    text=tostring(state.layerScrollMax or 999),
    decimals=0,
    onchange=function()
      state.layerScrollMax = mainDlg.data.layerScrollMax
      updateLayerScrollStatusLabel(state, mainDlg)
      M.requestRender(state)
    end
  }
  
  mainDlg:label{id="layerScrollStatus", text="Layer scroll: OFF"}
  
  -- Debug options
  mainDlg:separator{text="Debug"}
  
  mainDlg:check{
    id="useNative",
    label="Use Native Bridge",
    selected=state.useNative or true,
    onclick=function()
      state.useNative = mainDlg.data.useNative
      if state.useNative then
        -- Try to load native bridge
        local nativeBridge = require("core.native_bridge")
        nativeBridge.setForceDisabled(not state.useNative)
      end
      M.requestRender(state)
    end
  }
  
  mainDlg:check{
    id="useMesh",
    label="Use Mesh Renderer",
    selected=state.useMesh or false,
    onclick=function()
      state.useMesh = mainDlg.data.useMesh
      M.requestRender(state)
    end
  }
  
  mainDlg:check{
    id="showLightCone",
    label="Show Light Cone",
    selected=(state.lighting and state.lighting.showCone) or false,
    onclick=function()
      if not state.lighting then state.lighting = {} end
      state.lighting.showCone = mainDlg.data.showLightCone
      M.requestRender(state)
    end
  }
  
  -- Lighting controls
  mainDlg:slider{
    id="lightYaw",
    label="Light Yaw:",
    min=0,
    max=359,
    value=(state.lighting and state.lighting.yaw) or 0,
    onchange=function()
      if not state.lighting then state.lighting = {} end
      state.lighting.yaw = mainDlg.data.lightYaw
      M.requestRender(state)
    end
  }
  
  mainDlg:slider{
    id="lightPitch",
    label="Light Pitch:",
    min=-90,
    max=90,
    value=(state.lighting and state.lighting.pitch) or 0,
    onchange=function()
      if not state.lighting then state.lighting = {} end
      state.lighting.pitch = mainDlg.data.lightPitch
      M.requestRender(state)
    end
  }
  
  mainDlg:color{
    id="lightColor",
    label="Light Color:",
    color=(state.lighting and state.lighting.lightColor) or Color(255, 255, 255),
    onchange=function()
      if not state.lighting then state.lighting = {} end
      state.lighting.lightColor = mainDlg.data.lightColor
      M.requestRender(state)
    end
  }
  
  -- Model info display
  mainDlg:label{id="modelInfo", text="Voxel count: 0\nModel size: 0×0×0 voxels\nScale: 100%"}
  
  -- Buttons for dialogs and tools
  mainDlg:separator{text="Tools"}
  
  mainDlg:button{
    id="controls",
    text="View Controls",
    onclick=function()
      controls_dialog.open(state, {
        onChange = function(vp) M.requestRender(vp) end,
        onHelp = function() help_dialog.open() end
      })
    end
  }
  
  mainDlg:button{
    id="fxstack",
    text="FX Stack",
    onclick=function()
      fxstack_dialog.open(state)
    end
  }
  
  mainDlg:button{
    id="outline",
    text="Outline",
    onclick=function()
      outline_dialog.open(state, function()
        M.requestRender(state)
      end)
    end
  }
  
  mainDlg:button{
    id="animation",
    text="Animation",
    onclick=function()
      if not M.voxelModel or #M.voxelModel == 0 then
        app.alert("Please wait for the model to render first.")
        return
      end
      animation_dialog.open(state, M.voxelModel, M.modelDimensions)
    end
  }
  
  mainDlg:button{
    id="export",
    text="Export",
    onclick=function()
      if not M.voxelModel or #M.voxelModel == 0 then
        app.alert("Please wait for the model to render first.")
        return
      end
      export_dialog.open(state)
    end
  }
  
  mainDlg:button{
    id="help",
    text="Help",
    onclick=function()
      help_dialog.open()
    end
  }
  
  -- Create the preview canvas
  previewDlg:canvas{
    id="preview",
    width=300,
    height=300,
    onpaint=function(ev)
      local ctx = ev.context
      if M.previewImage then
        ctx:drawImage(M.previewImage, 0, 0)
      else
        ctx:setColor(Color(128, 128, 128))
        ctx:fillRect(0, 0, 300, 300)
        ctx:setColor(Color(255, 255, 255))
        ctx:fillText("Rendering...", 120, 150)
      end
    end,
    onmousemove=function(ev)
      if ev.button == MouseButton.MIDDLE or (ev.button == MouseButton.LEFT and ev.altKey) then
        -- Orbit camera (TODO)
        M.requestRender(state, "mouseMove")
      elseif ev.button == MouseButton.LEFT then
        -- Trackball rotation
        if not state.mouseTracking then
          state.mouseTracking = {
            startX = ev.x,
            startY = ev.y
          }
        else
          local dx = ev.x - state.mouseTracking.startX
          local dy = ev.y - state.mouseTracking.startY
          
          if math.abs(dx) > 2 or math.abs(dy) > 2 then
            local w, h = previewDlg.bounds.width, previewDlg.bounds.height
            local ax, ay, az, angle = math_utils.mouseToTrackball(
              state.mouseTracking.startX, state.mouseTracking.startY,
              ev.x, ev.y,
              w, h
            )
            
            if angle > 0.1 then
              local m = math_utils.createAxisAngleMatrix(ax, ay, az, angle)
              state.rotationMatrix = math_utils.multiplyMatrices(m, state.rotationMatrix)
              
              -- Update Euler angles
              local euler = math_utils.matrixToEuler(state.rotationMatrix)
              state.xRotation = euler.x
              state.yRotation = euler.y
              state.zRotation = euler.z
              
              state.mouseTracking.startX = ev.x
              state.mouseTracking.startY = ev.y
              
              M.requestRender(state, "mouseMove")
            end
          end
        end
      else
        state.mouseTracking = nil
      end
    end,
    onmouseup=function(ev)
      state.mouseTracking = nil
    end
  }
  
  -- Add a close button to the preview window
  previewDlg:button{
    id="previewClose",
    text="Close Preview",
    onclick=function()
      previewDlg:close()
    end
  }
  
  -- Show both dialogs
  mainDlg:show{wait=false}
  previewDlg:show{wait=false}
  
  return mainDlg, previewDlg
end

return M