-- fileUtils: placeholder for export helpers (expand with original as needed)
local fileUtils = {}

function fileUtils.saveText(path, text)
  local ok, f = pcall(function() return io.open(path, "wb") end)
  if ok and f then
    f:write(text or "")
    f:close()
    return true
  end
  return false, "Cannot write file"
end

return fileUtils