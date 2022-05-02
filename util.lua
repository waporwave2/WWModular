--util

function phzstep(phz,fr)
  phz+=(fr+1)*0.189841269841
  phz=((phz+1)%2)-1 --wrap into -1,1
  return phz
end

-- position of an in/out port on a module
function iop(mod,y,f)
  local lft=f and 2 or 17
  local dwn=6+8*(y-1)
  return {mod.x+lft,mod.y+dwn}
end

-- get wire index the connects to a module
-- p: whether to search the start of the wire (p=1) or the end (p=3)
-- b: which input/output index to find. b=-1 for any
function wirex(mod,p,b)
  assert(p==1 or p==3)
  for wi,wire in ipairs(wires) do
    if wire[p]==mod and (b==-1or wire[4]==b) then
      return wi
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
      for x=1,#modules do
        conin=true
        -- start dragging wire(?)
        for y=1,#modules[x].i do
          local p=iop(modules[x],y,conin)
          if (p[1]-mx)^2+(p[2]-my)^2<25 then
            local wi=wirex(modules[x],3,y)
            if wi>0 then
              concol=wires[wi][5]
              con=wires[wi][1]
              conid=wires[wi][2]
              conin=false
              deli(wires,wi)
            else
              con=modules[x]
              conid=y
              conin=true
              concol=rnd(4)+8
            end
          end
        end
        if con!=nil then
          break
        end
        conin=false
        for y=1,#modules[x].o do
          local p=iop(modules[x],y,conin)
          if (p[1]-mx)^2+(p[2]-my)^2<25 then
            con=modules[x]
            conid=y
            conin=false
            concol=rnd(4)+8
          end
        end
        if con!=nil then
          break
        end



        local h=#modules[x].o
        if #modules[x].i>h then
          h=#modules[x].i
        end
        if not modules[x].ungrabable and
        mx>modules[x].x and
        mx<modules[x].x+27 and
        my>modules[x].y and
        my<modules[x].y+8*h+4 then
          held=x
          anchor[1]=modules[x].x-mx
          anchor[2]=modules[x].y-my
        end
      end
    else
      modules[held].x=mx+anchor[1]
      modules[held].y=my+anchor[2]
    end
  end
end

function modulerelease()
  held=nil
  if con!=nil then
    for x=1,#modules do
      if x!=con then
        if not conin then
          for y=1,#modules[x].i do
            local p=iop(modules[x],y,true)
            if (p[1]-mx)^2+(p[2]-my)^2<25 then
              local wi=wirex(modules[x],3,y)
              if wi>0 then
                deli(wires,wi)
              end
              add(wires,{con,conid,modules[x],y,concol})


            end
          end
        else
          for y=1,#modules[x].o do
            local p=iop(modules[x],y,false)
            if (p[1]-mx)^2+(p[2]-my)^2<25 then
              add(wires,{modules[x],y,con,conid,concol})


            end
          end
        end
      end
    end
  end
  con=nil
end

function inmodule(xp,yp)
  for ii,mod in ipairs(modules) do
    local h=max(#mod.o,#mod.i)
    if not mod.ungrabable and
    xp>mod.x and
    xp<mod.x+27 and
    yp>mod.y and
    yp<mod.y+8*h+4 then
      return ii
    end
  end
  return -1
end

function delmod()
  local mod=modules[selectedmod]
  if not mod.undeletable then
    for x=1,#mod.i do
      local wi=wirex(mod,3,-1)
      if wi>0then
        deli(wires,wi)
      end
    end
    for x=1,#mod.o do
      local wi=wirex(mod,1,-1)
      if wi>0then
        deli(wires,wi)
      end
    end
    del(modules,mod)
  end
end
