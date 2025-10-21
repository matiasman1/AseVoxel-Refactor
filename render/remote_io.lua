-- render/remote_io.lua
-- IO helpers and event pump split from remoteRenderer

local IO = {}

function IO.write_bytes(path, bytes)
  local f, err = io.open(path, "wb"); if not f then return nil, err end
  f:write(bytes); f:close(); return true
end

function IO.temp_dir()
  local base = app.fs.userConfigPath or "."
  local dir = app.fs.joinPath(base, "AseVoxelRemote")
  if not app.fs.isDirectory(dir) then pcall(function() app.fs.makeDirectory(dir) end) end
  return dir
end

function IO.load_png_as_image(path)
  local spr=nil
  local ok, err = pcall(function() spr = Sprite{ fromFile = path } end)
  if not ok or not spr then return nil, "Failed to open PNG: "..tostring(err) end
  local img=nil
  pcall(function() if spr.cels and #spr.cels>=1 then img = spr.cels[1].image:clone() end end)
  pcall(function() app.activeSprite = spr; app.command.CloseFile() end)
  if not img then return nil, "No image data in loaded PNG" end
  return img
end

function IO.pump(ms)
  if app and app.wait then pcall(function() app.wait(ms or 10) end)
  else pcall(function() app.refresh() end) end
end

function IO.spin_until(pred, timeout_sec)
  local t0 = os.clock()
  while (os.clock() - t0) < (timeout_sec or 5) do
    if pred() then return true end
    IO.pump(10)
  end
  return false
end

return IO