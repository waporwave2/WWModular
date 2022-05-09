function unsplit(sep,...)
 local s,any=""
 for elem in all{...} do
  if any then s..=sep end
  any=true
  s..=tostr(elem)
 end
 return s
end

function export_synth()
  printh(build_export_string(),"wwmodular_patch"..projid..".p8l",true)
  dset(0,projid)
end

function build_export_string()
  local str="wwm v1\nmodules\n"-- sync w/ importer
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

function handle_file()
  import_state=0

  local ln=""
  while stat(120) do
    -- move data from dropped file into 0x4300
    local len=serial(0x800,0x4300,0x1000)

    for i=0,len-1 do
      local bb=@(0x4300+i)
      local c=chr(bb)
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
  elseif import_state==-2 then
    sample[samplesel]=sub(sample[samplesel],1,0x7ff0)
  elseif import_state>-1 then
    toast"success"
  end
end
function import_line(ln)
  -- if import_state~=-1 then
  --   pq("processing",ln)
  -- end
  if import_state==-2 then
    --sample
    sample[samplesel]..=ln
  elseif import_state==-1 then
    --error
  elseif import_state==0 then
    if ln=="wwm v1" then --sync w/ exporter
      import_state=1
      --initialize some values
      pg=1
      playing=false
      selectedmod=-1
      held,con,rcmenu,rcfunc,leftbar,speaker=nil
      modules,wires,pgtrg,page,mem={},{},{},{},{[0]=0}
      leftbar,speaker,trkp=0
    elseif ln=="wwsample" then
      import_state=-2
      samplesel%=#sample
      samplesel+=1
      sample[samplesel]=""
      toast("saved sample to slot "..samplesel)
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
  local str=unsplit(":",ii,mod.saveid,mod.x,mod.y)
  if mod.saveid=="knobs" then
    str..=":"..unsplit(":",mem[mod.nob_1],mem[mod.nob_2],mem[mod.nob_3],mem[mod.nob_4])
  elseif mod.saveid=="mixer" then
    -- str..=":"..#mod.i --TODO fix this for new mem i/o system
  end
  return str
end
function import_module(ln)
  local ix,saveid,x,y,k1,k2,k3,k4=unpack(split(ln,":"))
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
    elseif saveid=="knobs"then
      mem[mod.nob_1],mem[mod.nob_2],mem[mod.nob_3],mem[mod.nob_4]=k1,k2,k3,k4
    elseif saveid=="mixer"then
      if k1==2 then
        mod:propfunc(2)
      else
        for i=1,(k1/2-2) do
          mod:propfunc(1)
        end
      end
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
  local wix,iix,sloti,oix,sloto,value=unpack(split(ln,":"))
  if wix and iix and sloti and oix and sloto and value then
    local modi,modo = modules[iix],modules[oix]
    if modi and modo and sloti<=#modi.oname and sloto<=#modo.iname then
      assert(wix==#wires+1)
      addwire{modi,sloti,modo,sloto,value}
      return true
    end
  end
end

function export_pgtrg(ln)
  return unsplit(":",unpack(pgtrg))
end
function import_pgtrg(ln)
  local list=split(ln,":")
  if list and #list==6 then
    for ii,val in ipairs(list) do
      pgtrg[ii] = val=="true"
    end
    return true
  end
end

function export_page(ii,sheet)
  local ids={}
  for column in all(sheet) do
    for note in all(column) do
      assert(#note==3)
      add(ids,note[3])
    end
  end

  return unsplit(":",ii,unpack(ids))
end
function import_page(ln)
  local ids=split(ln,":")
  if #ids==97 then --6*16+1
    local sheet,ii={},2 --skip first ii (page index)
    page[ids[1]]=sheet
    for xx=1,6 do
      local column=add(sheet,{})
      for yy=1,16 do
        local dat=ids[ii]
        -- note id, octave
        add(column,import_note(dat%256,dat\256))
        ii+=1
      end
    end
    return true
  end
end
