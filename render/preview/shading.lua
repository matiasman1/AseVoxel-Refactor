-- Shading dispatch (Basic/Stack/Dynamic). Phase 2 will port originals.
local shading = {}

function shading.apply(model, params, cam)
  -- Pass-through in Phase 1
  return model
end

return shading