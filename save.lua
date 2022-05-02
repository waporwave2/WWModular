-- todo pgtrg

function unsplit(sep,...)
 local s=""
 local any
 for elem in all{...} do
  if any then
    s..=sep
  else
    any=true
  end
  s..=tostr(elem)
 end
 return s
end

function export_synth()
  printh(build_export_string(),"song.p8l",true)
end

SAVE_VERSION=1
function build_export_string()
  local str="wwm v"..SAVE_VERSION.."\nmodules\n"
  local index={}
  for ii,mod in ipairs(modules) do
    index[mod]=ii
    if mod.saveid then
      str..=unsplit(":",ii,mod.saveid,mod.x,mod.y).."\n"
    end
  end
  str..="wires\n"
  for ii,wire in ipairs(wires) do
    local imodindex = index[wire[1]]
    assert(imodindex)
    local omodindex = index[wire[3]]
    assert(omodindex)
    str..=unsplit(":",ii,imodindex,wire[2],omodindex,wire[4],tostr(wire[5],1)).."\n"
  end
  return str
end

function import_synth()
  modules={}
  wires={}
  import_state=0

  local ln=""
  while stat(120) do
    -- move data from dropped file into 0x4300
    local len=serial(0x800,0x4300,0x1000)

    for i=0,len-1 do
      local bb=@(0x4300+i)
      local c=chr(bb)
      assert(c,bb)
      if c=="\n" then
        import_line(ln)
        ln=""
      elseif c~="\r" then
        ln..=c
      end
    end
  end
  import_line(ln) --leftovers
end
function import_line(ln)
  -- if import_state~=-1 then
  --   pq("processing",ln)
  -- end

  if import_state==-1 then
    -- error
  elseif import_state==0 then
    if ln=="wwm v"..SAVE_VERSION then
      import_state=1
    else
      import_state=-1
      printh("bad file header; old version?: "..ln)
    end
  elseif import_state==1 then
    if ln=="modules" then
      import_state=2
    else
      import_state=-1
      printh("bad module header: "..ln)
    end
  elseif import_state==2 then
    -- importing modules
    if ln=="wires" then
      import_state=3
    elseif not import_module(ln) then
      printh("bad module: "..ln)
      import_state=-1
    end
  elseif import_state==3 then
    -- importing wires
    if ln=="" then
      import_state=4
    elseif not import_wire(ln) then
      printh("bad wire: "..ln)
      import_state=-1
    end
  end
end
function import_module(ln)
  local mi,saveid,x,y=unpack(split(ln,":"))
  local maker=all_module_makers[saveid]
  if maker then
    modules[mi]=maker()
    modules[mi].x=x
    modules[mi].y=y
    if saveid=="leftbar" then
      leftbar=modules[mi]
    end
    return true
  end
end
function import_wire(ln)
  local wi,indexi,sloti,indexo,sloto,value=unpack(split(ln,":"))
  if wi and indexi and sloti and indexo and sloto and value then
    local modi = modules[indexi]
    local modo = modules[indexo]
    if modi and modo and sloti<=#modi.oname and sloto<=#modo.iname then
      wires[wi]={modi,sloti,modo,sloto,value}
      return true
    end
  end
end
