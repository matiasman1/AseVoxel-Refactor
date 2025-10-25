-- Rotation helpers (Phase 2: port full trackball/Euler helpers)
local rotation = {}

function rotation.deg2rad(d) return (d or 0) * math.pi / 180 end
function rotation.rad2deg(r) return (r or 0) * 180 / math.pi end

return rotation