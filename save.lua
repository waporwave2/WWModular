function export_synth()
  printh(build_export_string(),"wwmodular_patch"..projid..".p8l",true)
  dset(0,projid)
end

function build_export_string()
  local str="wm02\nmodules\n" -- sync version w/ importer
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

  str..="samples\n"
  for ii,sample in ipairs(samples) do
    str..=export_sample(ii,sample).."\n"
  end

  return str
end

function handle_file()
  serial(0x800,0x4300,4) --read 4 magic bytes
  if $0x4300==0x3230.6d77 then --wm02
    import_state,samplesel,pg,trkp,selectedmod,   playing,held,con,rcmenu,rcfunc,leftbar,speaker=unpacksplit"1,1,1,0,-1"
    modules,wires,pgtrg,page,mem={},{},{},{},{[0]=0}
    samples=split"~,~,~,~,~,~,~,~"

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
    if import_state>=0 then
      toast"patch imported"
    end
  elseif $0x4300==0x6173.6d77 then --wmsa
    samplesel%=#samples
    samplesel+=1
    local len=serial(0x800,0x8000,0x7ff0)
    samples[samplesel]=chr(peek(0x8000,len))

    toast("imported sample #"..samplesel)
    while stat(120) do
      serial(0x800,0x8000,0x7ff0)
      toast("partially imported sample #"..samplesel)
    end
  else
    toast("bad magic bytes: "..tostr($0x4300,1))
    while stat(120) do
      serial(0x800,0x8000,0x7ff0)
    end
  end
end

function import_line(ln)
  if(ln=="")return
  if import_state==1 then
    if ln=="modules" then
      import_state=2
    else
      import_state=-1
      toast("bad file header: "..ln)
    end
  elseif import_state==2 then
    if ln=="wires" then
      import_state=3
    elseif not import_module(ln) then
      toast("bad module: "..ln)
      import_state=-1
    end
  elseif import_state==3 then
    if ln=="pgtrg" then
      import_state=4
    elseif not import_wire(ln) then
      toast("bad wire: "..ln)
      import_state=-1
    end
  elseif import_state==4 then
    if ln=="pages" then
      import_state=5
    elseif not import_pgtrg(ln) then
      toast("bad pgtrg: "..ln)
      import_state=-1
    end
  elseif import_state==5 then
    if ln=="samples" then
      import_state=6
    elseif not import_page(ln) then
      toast("bad page: "..ln)
      import_state=-1
    end
  elseif import_state==6 then
    if ln=="" then
      import_state=7
    elseif not import_sample(ln) then
      toast("bad sample: "..ln)
      import_state=-1
    end
  end
end

function export_module(ii,mod)
  local str=unsplit(":",ii,mod.saveid,mod.x,mod.y)
  if mod.saveid=="knobs" then
    str..=":"..unsplit(":",mem[mod[1]],mem[mod[2]],mem[mod[3]],mem[mod[4]])
  elseif mod.saveid=="mixer" then
    str..=":"..(#mod.iname)
  end
  return str
end
function import_module(ln)
  local ix,saveid,x,y,k1,k2,k3,k4=unpacksplit(ln,":")
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
      mem[mod[1]],mem[mod[2]],mem[mod[3]],mem[mod[4]]=k1,k2,k3,k4
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
  local wix,iix,sloti,oix,sloto,value=unpacksplit(ln,":")
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

function export_sample(ii,sample)
  return unsplit(":",ii,ord(sample,1,#sample))
end
function import_sample(ln)
  local dat=split(ln,":")
  samples[dat[1]]=chr(unpack(dat,2))
  return true
end

-- function cpsam(n) printh(samples[n],"@clip") end
