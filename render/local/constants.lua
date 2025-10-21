-- Shared constants for the local preview renderer

local C = {}

C.UNIT_CUBE_VERTICES = {
  {-0.5,-0.5,-0.5}, { 0.5,-0.5,-0.5}, { 0.5, 0.5,-0.5}, {-0.5, 0.5,-0.5},
  {-0.5,-0.5, 0.5}, { 0.5,-0.5, 0.5}, { 0.5, 0.5, 0.5}, {-0.5, 0.5, 0.5},
}

C.FACE_DEFS = {
  front = {4,3,2,1},  -- z-
  back  = {5,6,7,8},  -- z+
  right = {2,3,7,6},  -- x+
  left  = {1,4,8,5},  -- x-
  top   = {4,3,7,8},  -- y+
  bottom= {1,2,6,5},  -- y-
}

C.FACE_NORMALS = {
  front={0,0,-1}, back={0,0,1}, right={1,0,0},
  left={-1,0,0},  top={0,1,0},  bottom={0,-1,0},
}

function C.faceOrder()
  return {"front","back","right","left","top","bottom"}
end

function C.clampByte(v)
  return math.max(0, math.min(255, math.floor(v or 0)))
end

return C