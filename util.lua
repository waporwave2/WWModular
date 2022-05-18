--util

function phzstep(phz,fr)
  phz+=(fr+1)*0.189841269841
  return ((phz+1)%2)-1 --wrap into -1,1
end

-- position of an in/out port on a module
function iop(mod,pix,is_input)
  return mod.x+(is_input and 2 or 19), mod.y+5*pix+2
end
-- _iop=iop
-- function iop(...)
--   local x,y=_iop(...)
--   dd(rectwh,x-1,y-1,3,3,8)
--   return x,y
-- end

function iocollide(x,y,...)
  local px,py=iop(...)
  return rect_collide(px-3,py-2,10,5, x,y)
end

-- get wire index the connects to a module
-- p: whether to search the start of the wire (p=1) or the end (p=3)
-- b: which input/output index to find. b=nil for any
function wirex(mod,p,b)
  -- assert(p==1 or p==3)
  for ix,wire in ipairs(wires) do
    if wire[p]==mod and (not b or wire[4]==b) then
      return ix
    end
  end
end

function moduleclick()
  if con==nil then
    if held==nil then
      for mix,mod in ipairs(modules) do
        conin=true
        for ipix=1,#mod.iname do
          -- ipix = "in port index"
          if iocollide(mx,my,mod,ipix,conin) then
            local wix=wirex(mod,3,ipix)
            if wix then
              concol=wires[wix][5]
              con=wires[wix][1]
              conid=wires[wix][2]
              conin=false
              delwire(wix)
            else
              con=mod
              conid=ipix
              conin=true
              concol=rnd(wirecols)
            end
          end
        end
        if con then
          break
        end
        conin=false
        for opix=1,#mod.oname do
          -- opix = "out port index"
          if iocollide(mx,my,mod,opix,conin) then
            con=mod
            conid=opix
            conin=false
            concol=rnd(wirecols)
          end
        end
        if con then
          break
        end


        if not mod.ungrabable and mod_collide(mod,mx,my) then
          held=mix
          anchorx=mod.x-mx
          anchory=mod.y-my
        end
      end
    else
      modules[held].x=mx+anchorx
      modules[held].y=my+anchory
    end
  end
end

function modulerelease()
  held=nil
  if con then
    for mix,mod in ipairs(modules) do
      if mix!=con then
        if not conin then
          for ipix=1,#mod.iname do
            if iocollide(mx,my,mod,ipix,true) then
              delwire(wirex(mod,3,ipix))
              addwire{con,conid,mod,ipix,concol}


            end
          end
        else
          for opix=1,#mod.oname do
            if iocollide(mx,my,mod,opix,false) then
              addwire{mod,opix,con,conid,concol}


            end
          end
        end
      end
    end
  end
  con=nil
end

function mod_collide(mod,xp,yp)
  local h=5*max(#mod.iname,#mod.oname)+7
  return rect_collide(mod.x-1,mod.y-1,36,h, xp,yp)
end

function inmodule(xp,yp)
  for mix,mod in ipairs(modules) do
    if not mod.ungrabable and mod_collide(mod,xp,yp) then
      return mix
    end
  end
  return -1
end

function delmod()
  local mod=modules[selectedmod]
  if not mod.undeletable then
    repeat
      local wix=wirex(mod,3)
      delwire(wix)
    until not wix
    repeat
      local wix=wirex(mod,1)
      delwire(wix)
    until not wix
    deli(modules,selectedmod)
  end
end

function debugmod( mod)
  mod=mod or modules[selectedmod]
  if mod then
    pq(mod.saveid,"i/o: index | name | addr | value")
    for ix,name in ipairs(mod.iname) do
      pq(" i",ix,name,mod[name],mem[mod[name]])
    end
    for ix,name in ipairs(mod.oname) do
      pq(" o",ix,name,mod[name],mem[mod[name]])
    end
  end
end

function addwire(wire)
  -- set input address of module we're connecting-to
  local frommod,fromport,tomod,toport=unpack(wire)
  local fromname,toname=frommod.oname[fromport],tomod.iname[toport]
  tomod[toname] = frommod[fromname]
  add(wires,wire)
end

function drawwire(x0,y0,x1,y1,col)
  if hqmode then
    local dx,dy=x1-x0,y1-y0+0.1 --0.1 to ensure dy~=0
    -- calc parabola params: y(x) = a*(x-xc)^2+h
    -- custom formula by pancelor
    local a,h,xc  do
      -- assert(dy~=0)
      local t=1/(1+2.7182818^(dy/-32)) -- adjust last constant here for different wire tension
      local xc_rel_x0=dx*t
      a=dy/(dx*dx*(1-2*t))
      h=-a*xc_rel_x0*xc_rel_x0
      xc=xc_rel_x0+x0
    end

    line(col)
    line(x0,y0)
    local step=dx/8
    for x=x0+step,x1-step,step do
      local dxc=x-xc
      line(x,y0+a*dxc*dxc+h)
    end
    line(x1,y1)
  else
    line(x0,y0,x1,y1,col)
  end
end

-- id may be nil
-- delete the wire and reset the input address
function delwire(id)
  local wire = wires[id]
  if wire then
    local tomod,toport = wire[3],wire[4]
    local toname=tomod.iname[toport]
    tomod[toname]=0 --set address to 0 (mem[0] is always 0)
    deli(wires,id)
  end
end
