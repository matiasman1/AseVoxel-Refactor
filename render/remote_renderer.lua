-- render/remote_renderer.lua
-- Public API built on helpers; functions kept small

local J = require("render.remote_json")
local IO = require("render.remote_io")

local Remote = {}

local DEFAULT_URL = "ws://127.0.0.1:9000"
local _url = DEFAULT_URL
local _ws, _connected, _status, _lastError = nil, false, "idle", nil
local _inflight, _pendingReady, _pending = false, false, nil

local function onMessage(mt, data)
  if mt == WebSocketMessageType.OPEN then _connected=true; _status="connected"; _lastError=nil
  elseif mt == WebSocketMessageType.CLOSE then _connected=false; _status="closed"
  elseif mt == WebSocketMessageType.TEXT and _inflight and not _pendingReady then _pending={kind="text",data=data or ""}; _pendingReady=true
  elseif mt == WebSocketMessageType.BINARY and _inflight and not _pendingReady then _pending={kind="binary",data=data or ""}; _pendingReady=true
  end
end

local function ensure_socket()
  if _ws then return end
  _ws = WebSocket{ onreceive=onMessage, url=_url, deflate=false, minreconnectwait=0.5, maxreconnectwait=2.0 }
  _status = "created"
end

local function ensure_connected(timeout_sec)
  ensure_socket()
  if _connected then return true end
  _status = "connecting"
  local ok, err = pcall(function() _ws:connect() end)
  if not ok then _lastError="connect() failed: "..tostring(err); _status="error"; return false end
  local ready = IO.spin_until(function() return _connected end, timeout_sec or 10)
  if not ready then _lastError="timeout connecting to "..tostring(_url); _status="timeout" end
  return ready
end

function Remote.setUrl(u)
  if type(u)=="string" and u~="" then
    _url = u
    if _ws then pcall(function() _ws:close() end) end
    _ws, _connected, _status, _lastError = nil, false, "idle", nil
  end
end

function Remote.getStatus()
  return { connected=_connected, status=_status, lastError=_lastError, url=_url }
end

function Remote.reconnect()
  if _ws then pcall(function() _ws:close() end) end
  _ws, _connected, _status, _lastError = nil, false, "reconnecting", nil
  return ensure_connected(10)
end

function Remote.render(voxelsFlat, options)
  if _inflight then return nil, "busy" end
  local ok = ensure_connected(10); if not ok then return nil, _lastError or "Cannot connect" end
  local voxObjs = {}
  for i=1,#voxelsFlat do local v=voxelsFlat[i]
    voxObjs[i] = { x=v[1], y=v[2], z=v[3], color={ r=v[4], g=v[5], b=v[6], a=v[7] } }
  end
  local payload = J.encode({ voxelsFlat=voxelsFlat, voxels=voxObjs, options=options or {} })
  _inflight, _pending, _pendingReady = true, nil, false
  local sentOk, sendErr = pcall(function() _ws:sendText(payload) end)
  if not sentOk then _inflight=false; _status="error"; _lastError="sendText failed: "..tostring(sendErr); return nil, _lastError end
  pcall(function() _ws:sendPing("r") end)
  local got = IO.spin_until(function() return _pendingReady end, 15)
  if not got then _inflight=false; _lastError="Timed out waiting for render response"; _status="timeout"; return nil, _lastError end
  local resp = _pending; _pending, _pendingReady, _inflight = nil, false, false
  local png_bytes = (resp.kind=="text") and J.b64_decode(resp.data or "") or (resp.kind=="binary" and (resp.data or "") or nil)
  if not png_bytes or #png_bytes==0 then _lastError="No image data"; return nil, _lastError end
  local dir = IO.temp_dir(); local path = app.fs.joinPath(dir, "remote_render.png")
  local ok2, err2 = IO.write_bytes(path, png_bytes); if not ok2 then _lastError="Failed to write PNG: "..tostring(err2); return nil, _lastError end
  local img, lerr = IO.load_png_as_image(path); if not img then _lastError=lerr or "Failed to load PNG"; return nil, _lastError end
  _status="ok"; return img
end

return Remote