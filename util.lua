--util

function phzstep(phz,fr)
  phz+=(fr+1)*0.189841269841
  phz=((phz+1)%2)-1 --wrap into -1,1
  return phz
end

-- position of an in/out port on a module
function iop(mod,y,is_input)
  local lft=is_input and 2 or 17
  local dwn=6+8*(y-1)
  return {mod.x+lft,mod.y+dwn}
end

-- get wire index the connects to a module
-- p: whether to search the start of the wire (p=1) or the end (p=3)
-- b: which input/output index to find. b=-1 for any
function wirex(mod,p,b)
  assert(p==1 or p==3)
  for ix,wire in ipairs(wires) do
    if wire[p]==mod and (b==-1or wire[4]==b) then
      return ix
    end
  end
  return -1
end

function test(mod)
  mod.i[1]=leftbar.o[1]
end

function moduleclick()
  if con==nil then
    if held==nil then
      for mix,mod in ipairs(modules) do
        conin=true
        -- start dragging wire(?)
        for ipix=1,(mod.i and #mod.i or 0) do
          -- ipix = "in port index"
          local p=iop(mod,ipix,conin)
          if (p[1]-mx)^2+(p[2]-my)^2<25 then
            local wix=wirex(mod,3,ipix)
            if wix>0 then
              concol=wires[wix][5]
              con=wires[wix][1]
              conid=wires[wix][2]
              conin=false
              delwire(wix)
            else
              con=mod
              conid=ipix
              conin=true
              concol=rnd(4)+8
            end
          end
        end
        if con then
          break
        end
        conin=false
        for opix=1,(mod.o and #mod.o or 0) do
          -- opix = "out port index"
          local p=iop(mod,opix,conin)
          if (p[1]-mx)^2+(p[2]-my)^2<25 then
            con=mod
            conid=opix
            conin=false
            concol=rnd(4)+8
          end
        end
        if con then
          break
        end


        local ol,il = (mod.o and #mod.o or 0),(mod.i and #mod.i or 0)
        local h=max(ol,il)
        if not mod.ungrabable and
        mx>mod.x and
        mx<mod.x+27 and
        my>mod.y and
        my<mod.y+8*h+4 then
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
          for ipix=1,(mod.i and #mod.i or 0) do
            local p=iop(mod,ipix,true)
            if (p[1]-mx)^2+(p[2]-my)^2<25 then
              local wix=wirex(mod,3,ipix)
              if wix>0 then
                delwire(wix)
              end
              add(wires,{con,conid,mod,ipix,concol})


            end
          end
        else
          for opix=1,(mod.o and #mod.o or 0) do
            local p=iop(mod,opix,false)
            if (p[1]-mx)^2+(p[2]-my)^2<25 then
              add(wires,{mod,opix,con,conid,concol})


            end
          end
        end
      end
    end
  end
  con=nil
end

function inmodule(xp,yp)
  for mix,mod in ipairs(modules) do
    local ol,il = (mod.o and #mod.o or 0),(mod.i and #mod.i or 0)
    local h=max(ol,il)
    if not mod.ungrabable and
    xp>mod.x and
    xp<mod.x+27 and
    yp>mod.y and
    yp<mod.y+8*h+4 then
      return mix
    end
  end
  return -1
end

function delmod()
  local mod=modules[selectedmod]
  if not mod.undeletable then
    repeat
      local wix=wirex(mod,3,-1)
      if wix>0then
        delwire(wix)
      end
    until wix==-1
    repeat
      local wix=wirex(mod,1,-1)
      if wix>0then
        delwire(wix)
      end
    until wix==-1
    deli(modules,selectedmod)
  end
end

--resets input value, deletes wire
function delwire(id)
  local wire = wires[id]
  wire[3].i[wire[4]]=0
  deli(wires,id)
end
