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
  local str="wwm v"..SAVE_VERSION.."\n"

  str..="modules\n"
  local modlookup={}
  for ii,mod in ipairs(modules) do
    modlookup[mod]=ii
    str..=export_module(ii,mod).."\n"
  end

  str..="wires\n"
  for ii,wire in ipairs(wires) do
    str..=export_wire(ii,wire,modlookup).."\n"
  end

  str..="pgtrg\n"
  str..=export_pgtrg().."\n"

  str..="pages\n"
  for ii,sheet in ipairs(page) do
    str..=export_page(ii,sheet).."\n"
  end

  return str
end

function import_synth()
  modules={}
  wires={}
  pgtrg={}
  page={}
  leftbar=nil
  speaker=nil
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
  if import_state==-1 then
    toast"error! see host console"
  else
    toast"saved"
  end
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
    if ln=="pgtrg" then
      import_state=4
    elseif not import_wire(ln) then
      printh("bad wire: "..ln)
      import_state=-1
    end
  elseif import_state==4 then
    if ln=="pages" then
      import_state=5
    elseif not import_pgtrg(ln) then
      printh("bad pgtrg: "..ln)
      import_state=-1
    end
  elseif import_state==5 then
    -- importing pages
    if ln=="" then
      import_state=6
    elseif not import_page(ln) then
      printh("bad page: "..ln)
      import_state=-1
    end
  end
end

function export_module(ii,mod)
  return unsplit(":",ii,mod.saveid,mod.x,mod.y)
end
function import_module(ln)
  local ix,saveid,x,y=unpack(split(ln,":"))
  local maker=all_module_makers[saveid]
  if maker then
    local mod=maker()
    modules[ix]=mod
    mod.x=x
    mod.y=y
    if saveid=="leftbar" then
      leftbar=mod
    elseif saveid=="speaker" then
      speaker=mod
    end
    return true
  end
end

function export_wire(ii,wire,modlookup)
  local imodindex = modlookup[wire[1]]
  assert(imodindex)
  local omodindex = modlookup[wire[3]]
  assert(omodindex)
  local value = tostr(wire[5],1)
  return unsplit(":",ii,imodindex,wire[2],omodindex,wire[4],value)
end
function import_wire(ln)
  local ix,indexi,sloti,indexo,sloto,value=unpack(split(ln,":"))
  if ix and indexi and sloti and indexo and sloto and value then
    local modi = modules[indexi]
    local modo = modules[indexo]
    if modi and modo and sloti<=#modi.oname and sloto<=#modo.iname then
      wires[ix]={modi,sloti,modo,sloto,value}
      return true
    end
  end
end

function export_pgtrg(ln)
  return unsplit(":",pgtrg[1],pgtrg[2],pgtrg[3],pgtrg[4],pgtrg[5],pgtrg[6])
end
function import_pgtrg(ln)
  local list=split(ln,":")
  if list and #list==6 then
    for ii=1,6 do
      pgtrg[ii] = list[ii]=="true"
    end
    return true
  end
end

function export_page(ii,sheet)
  local ids={}
  for column in all(sheet) do
    for note in all(column) do
      assert(note[3])
      add(ids,note[3])
    end
  end

  return unsplit(":",ii,unpack(ids))
end
function import_page(ln)
  local ids=split(ln,":")
  if #ids==6*16+1 then
    local sheet={}
    page[ids[1]]=sheet

    local ii=2 --skip first (page index)
    for xx=1,6 do
      local column=add(sheet,{})
      for yy=1,16 do
        add(column,import_note(ids[ii]))
        ii+=1
      end
    end
    return true
  end
end
