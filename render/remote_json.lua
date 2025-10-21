-- render/remote_json.lua
-- Minimal JSON and base64 helpers split from remoteRenderer

local J = {}

local function escape_str(s)
  s = s:gsub('\\','\\\\'):gsub('"','\\"')
  s = s:gsub('\b','\\b'):gsub('\f','\\f'):gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t')
  return s
end

local function is_array(t)
  if type(t)~="table" then return false end
  local maxk=0
  for k,_ in pairs(t) do if type(k)~="number" then return false end if k>maxk then maxk=k end end
  return true
end

function J.encode(v)
  local tv=type(v)
  if tv=="nil" then return "null"
  elseif tv=="boolean" then return v and "true" or "false"
  elseif tv=="number" then return tostring(v)
  elseif tv=="string" then return '"'..escape_str(v)..'"'
  elseif tv=="table" then
    if is_array(v) then
      local parts={} for i=1,#v do parts[#parts+1]=J.encode(v[i]) end
      return "["..table.concat(parts,",").."]"
    else
      local parts={} for k,val in pairs(v) do parts[#parts+1]='"'..escape_str(tostring(k))..'":'..J.encode(val) end
      return "{"..table.concat(parts,",").."}"
    end
  end
  return "null"
end

function J.b64_decode(data)
  local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  data = data:gsub('[^'..b..'=]','')
  return (data:gsub('.', function(x)
    if x=='=' then return '' end
    local r,f='', (b:find(x)-1)
    for i=6,1,-1 do r = r .. (f % 2^i - f % 2^(i-1) > 0 and '1' or '0') end
    return r
  end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
    if #x~=8 then return '' end
    local c=0
    for i=1,8 do c = c + (x:sub(i,i)=='1' and 2^(8-i) or 0) end
    return string.char(c)
  end))
end

return J