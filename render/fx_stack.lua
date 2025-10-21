-- render/fx_stack.lua
-- Moved from fxStack.lua (unchanged behavior); require paths updated

local fxStack = {}

fxStack.TOP_THRESHOLD = 0.25
fxStack.FACE_ORDER = { "top","bottom","front","back","left","right" }
fxStack.FACESHADE_DISPLAY_ORDER = { "top","bottom","left","right","front","back" }
fxStack.LOCAL_NORMALS = {
  top    = {0,-1,0}, bottom = {0,1,0},
  front  = {0,0,-1}, back   = {0,0,1},
  left   = {-1,0,0}, right  = {1,0,0},
}

fxStack.DEFAULT_ISO_ALPHA = {
  shape="Iso", type="alpha", scope="full", tintAlpha=false,
  colors={
    {r=255,g=255,b=255,a=255},
    {r=235,g=235,b=235,a=230},
    {r=210,g=210,b=210,a=210},
  }
}
fxStack.DEFAULT_FACESHADE_ALPHA = {
  shape="FaceShade", type="alpha", scope="full", tintAlpha=false,
  colors={
    {r=255,g=255,b=255,a=255},
    {r=255,g=255,b=255,a=180},
    {r=255,g=255,b=255,a=255},
    {r=255,g=255,b=255,a=220},
    {r=255,g=255,b=255,a=210},
    {r=255,g=255,b=255,a=230},
  }
}

local function clone(t) if type(t)~="table" then return t end local r={} for k,v in pairs(t) do r[k]=clone(v) end return r end
function fxStack.makeDefaultStack() return { modules={ clone(fxStack.DEFAULT_ISO_ALPHA), clone(fxStack.DEFAULT_FACESHADE_ALPHA) } } end

function fxStack.migrateIfNeeded(viewParams)
  if viewParams.fxStack and viewParams._fxStack_migrated then return end
  if not viewParams.fxStack then viewParams.fxStack = fxStack.makeDefaultStack() end
  local migrated=false
  if viewParams.isoColors then
    local c=viewParams.isoColors
    table.insert(viewParams.fxStack.modules,1,{shape="Iso",type="literal",scope="full",tintAlpha=false,
      colors={{r=c.top.r,g=c.top.g,b=c.top.b,a=c.top.a or 255},
              {r=c.left.r,g=c.left.g,b=c.left.b,a=c.left.a or 255},
              {r=c.right.r,g=c.right.g,b=c.right.b,a=c.right.a or 255}}})
    migrated=true
  end
  if viewParams.faceShaders and viewParams.faceShaders.colors then
    local fs=viewParams.faceShaders
    local function toC(t) return {r=t.r or 255,g=t.g or 255,b=t.b or 255,a=t.a or 255} end
    table.insert(viewParams.fxStack.modules,{
      shape="FaceShade", type=(fs.mode=="literal") and "literal" or "alpha", scope="full", tintAlpha=false,
      colors={ toC(fs.colors.top or {}), toC(fs.colors.bottom or {}), toC(fs.colors.front or {}),
               toC(fs.colors.back or {}), toC(fs.colors.left or {}), toC(fs.colors.right or {}) }
    })
    migrated=true
  end
  viewParams._fxStack_migrated = migrated or true
end

local function rotateVec(v,M) return { M[1][1]*v[1]+M[1][2]*v[2]+M[1][3]*v[3],
                                      M[2][1]*v[1]+M[2][2]*v[2]+M[2][3]*v[3],
                                      M[3][1]*v[1]+M[3][2]*v[2]+M[3][3]*v[3] } end
local function norm(v) local m=math.sqrt(v[1]^2+v[2]^2+v[3]^2) if m<1e-9 then return {0,0,0} end return {v[1]/m,v[2]/m,v[3]/m} end

function fxStack.computeRotatedNormals(R, viewDir)
  local o={}
  for face,n in pairs(fxStack.LOCAL_NORMALS) do
    local nr = rotateVec(n,R); local nn = norm(nr)
    o[face]={normal=nn, dot = nn[1]*viewDir[1]+nn[2]*viewDir[2]+nn[3]*viewDir[3]}
  end
  return o
end

function fxStack.selectIsoFaces(rotInfo)
  if not rotInfo then return { isoFaces={top=nil,left=nil,right=nil}, order={} } end
  local dTop = (rotInfo.top and rotInfo.top.dot) or -math.huge
  local dBottom = (rotInfo.bottom and rotInfo.bottom.dot) or -math.huge
  local topName = (dTop >= dBottom) and "top" or "bottom"
  local sideNames = { "front","back","left","right" }
  local sides,vis={},{ }
  for _,n in ipairs(sideNames) do local i=rotInfo[n]; if i then
    local e={ face=n, dot=i.dot or -math.huge, nx=(i.normal and i.normal[1]) or 0 }; sides[#sides+1]=e; if e.dot>0 then vis[#vis+1]=e end
  end end
  local pool = (#vis >= 2) and vis or sides
  table.sort(pool, function(a,b) return (a.dot or -1e9) > (b.dot or -1e9) end)
  local s1,s2 = pool[1], pool[2]; if not s1 or not s2 then return { isoFaces={ top=topName, left=s1 and s1.face, right=s2 and s2.face }, order={"top","left","right"} } end
  local leftName,rightName
  if (s1.nx or 0) > (s2.nx or 0) then rightName=s1.face; leftName=s2.face else rightName=s2.face; leftName=s1.face end
  local mapping={ top=topName, left=leftName, right=rightName }
  local ordered={}; if mapping.top then ordered[#ordered+1]="top" end; if mapping.left then ordered[#ordered+1]="left" end; if mapping.right then ordered[#ordered+1]="right" end
  return { isoFaces=mapping, order=ordered }
end

local faceToIndex = { top=1,bottom=2,front=3,back=4,left=5,right=6 }

local function computeIsoLiteralSidePair(rotInfo)
  local vis={}
  for name,info in pairs(rotInfo) do if info.dot and info.dot>0 then vis[name]=true end end
  local pairsOrdered={ {"front","right"}, {"right","back"}, {"back","left"}, {"left","front"} }
  local best,nilScore=nil,-1
  for _,pr in ipairs(pairsOrdered) do local a,b=pr[1],pr[2]
    if vis[a] and vis[b] then local s=(rotInfo[a].dot or 0)+(rotInfo[b].dot or 0)
      if s>nilScore then nilScore=s; best={first=a, second=b} end
    end
  end
  return best
end

local function applyModule(module, faceName, faceRoleIso, baseColor, voxelColorOriginal)
  if module.scope=="material" and module.materialColor then
    local mc=module.materialColor; local r,g,b,a = voxelColorOriginal.r, voxelColorOriginal.g, voxelColorOriginal.b, voxelColorOriginal.a or 255
    if not (r==mc.r and g==mc.g and b==mc.b and a==(mc.a or 255)) then return baseColor end
  end
  local idx
  if module.shape=="FaceShade" then
    idx = faceToIndex[faceName]
    if faceName=="top" then idx=faceToIndex.bottom elseif faceName=="bottom" then idx=faceToIndex.top end
  elseif module.shape=="Iso" then
    idx = (faceRoleIso=="top" and 1) or (faceRoleIso=="left" and 2) or (faceRoleIso=="right" and 3) or nil
  end
  if not idx or not module.colors[idx] then return baseColor end
  local mcol = module.colors[idx]
  local out = { r=baseColor.r, g=baseColor.g, b=baseColor.b, a=baseColor.a }
  if module.type=="literal" then
    out.r,out.g,out.b = mcol.r,mcol.g,mcol.b
  else
    local alphaNorm=(mcol.a or 255)/255
    local minB=0.2; local bright = minB + (1-minB)*alphaNorm
    out.r,out.g,out.b = math.floor(out.r*bright+0.5), math.floor(out.g*bright+0.5), math.floor(out.b*bright+0.5)
    if module.tintAlpha then
      out.r = math.floor(out.r * (mcol.r/255) + 0.5)
      out.g = math.floor(out.g * (mcol.g/255) + 0.5)
      out.b = math.floor(out.b * (mcol.b/255) + 0.5)
    end
  end
  return out
end

function fxStack.shadeFace(params, faceName, voxelColor)
  local stack = params.fxStack and params.fxStack.modules
  if not stack or #stack==0 then return voxelColor end
  if not params._frameIsoCache then
    local vd = params.viewDir or {0,0,1}
    local mag=math.sqrt(vd.x*vd.x+vd.y*vd.y+vd.z*vd.z)
    if mag>1e-6 then vd={x=vd.x/mag,y=vd.y/mag,z=vd.z/mag} else vd={x=0,y=0,z=1} end
    local rotInfo = fxStack.computeRotatedNormals(params.rotationMatrix, {vd.x,vd.y,vd.z})
    local isoSel = fxStack.selectIsoFaces(rotInfo)
    local sidePair = computeIsoLiteralSidePair(rotInfo)
    local literalRoles = { top="top", bottom="top" }
    if sidePair then
      literalRoles[sidePair.first] = "right"
      literalRoles[sidePair.second] = "left"
      local leftIsRight = literalRoles.left=="right" or literalRoles.right=="right"
      local leftIsLeft  = literalRoles.left=="left"  or literalRoles.right=="left"
      if leftIsRight then literalRoles.front="left"; literalRoles.back="left"
      elseif leftIsLeft then literalRoles.front="right"; literalRoles.back="right" end
    end
    local alphaRoles = {}
    if isoSel and isoSel.isoFaces then
      local isoTop, isoLeft, isoRight = isoSel.isoFaces.top, isoSel.isoFaces.left, isoSel.isoFaces.right
      if isoTop then alphaRoles[isoTop]="top" end
      if isoLeft then alphaRoles[isoLeft]="left" end
      if isoRight then alphaRoles[isoRight]="right" end
      local opposite = { top="bottom", bottom="top", left="right", right="left", front="back", back="front" }
      if isoTop and opposite[isoTop] then alphaRoles[opposite[isoTop]]="top" end
    end
    params._frameIsoCache = { rotInfo=rotInfo, isoSelection=isoSel, sidePair=sidePair, literalRoles=literalRoles, alphaRoles=alphaRoles }
  end
  local cache = params._frameIsoCache
  local roleIsoAlpha = cache.alphaRoles and cache.alphaRoles[faceName] or nil
  local roleIsoLiteral = cache.literalRoles and cache.literalRoles[faceName] or nil
  local working = { r=voxelColor.r, g=voxelColor.g, b=voxelColor.b, a=voxelColor.a }
  for _,mod in ipairs(stack) do
    local roleForModule = (mod.shape=="Iso") and ((mod.type=="literal") and roleIsoLiteral or roleIsoAlpha) or nil
    working = applyModule(mod, faceName, roleForModule, working, voxelColor)
  end
  return working
end

return fxStack