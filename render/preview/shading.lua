-- Basic shading placeholder: pass-through color & compute brightness by dot with viewDir
local shading = {}

-- params: may include lighting info. cam contains viewDir and rotationMatrix.
-- Returns a list of shaded voxels: { x,y,z, color={r,g,b,a}, shade = brightness }
function shading.apply(model, params, cam)
  local out = {}
  local vd = cam.viewDir or { x = 0, y = 0, z = 1 }
  -- Normalize view dir
  local mag = math.sqrt(vd.x*vd.x + vd.y*vd.y + vd.z*vd.z)
  if mag > 1e-6 then vd = { x = vd.x/mag, y = vd.y/mag, z = vd.z/mag } end

  for i, v in ipairs(model or {}) do
    -- Simple brightness: use facing approximation via z component after rotation
    local p = { x = v.x, y = v.y, z = v.z }
    local rv = params.rotationMatrix and params.rotationMatrix or cam.rotationMatrix
    -- We expect rotation has been applied upstream in pipeline; keep shade simple:
    local brightness = 1.0
    if v.color and v.color.r then
      -- approximate brightness from color luminance
      local r, g, b = v.color.r or 255, v.color.g or 255, v.color.b or 255
      brightness = ((r*0.299 + g*0.587 + b*0.114) / 255)
    end
    out[#out + 1] = {
      x = v.x, y = v.y, z = v.z,
      color = v.color,
      brightness = brightness
    }
  end

  return out
end

return shading