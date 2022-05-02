local modmenu={}
local modmenufunc={}
local modprop={}
local modpropfunc={}

--tracker
local trks={0,0} --xy position
local trkp=0
local page={}
local pg=1
local oct=1
local pgtrg={false,false,false,false,false,false}

--top menu
local rec=false
local pgmode=0
local playing=false
local tracker_mode=false

local oscbuf={}
local modules={}
local wires={}
local held=nil
local con=nil
local conin=true
local conid=0
local concol=3
local rcmenu=nil
local rcfunc=nil
local selectedmod=-1
local rcp={0,0}
local anchor={0,0}--grab offset



function dev_manyspawn()
  if not dev_setup then return end

  for i =1,4 do
   local mod=new_adsr()
   mod.x=20
   mod.y=(i*30) % 128
  end
end
function cpuok()
 return stat(1)<1 and stat(7)==60
end
function dev_outline_modules()
  if not dev_outlines then return end
  if tracker_mode then return end

  fillp(▒)
  for ii,mod in ipairs(modules) do
    local h=max(#mod.o,#mod.i)
    rect(mod.x,mod.y,mod.x+27,mod.y+8*h+4,5)
  end
  fillp()
end



function _init()
  --add modules to menu
  modmenu={
    "saw",
    "sin",
    "square",
    "mixer",
    "tri",
    "clip",
    "lfo",
    "adsr",
  }
  modmenufunc={
    new_saw,
    new_sine,
    new_square,
    new_mixer,
    new_tri,
    new_clip,
    new_lfo,
    new_adsr,
  }

  new_output()
  leftbar=new_leftbar()
  dev_manyspawn()

  menuitem(1,"export",export_synth)

  -- palette
  pal(split"129,5,134,15,12,1,7,8,9,10,11,6,13,14,15",1)
  palt(0,false)
  palt(14,true)
  if dev_palpersist then poke(0x5f2e,1) end

  -- mouse+kb
  poke(0x5f2d,0x1)
-- poke(0x5f5c,8,5) --keyrepeat

  -- font
  poke(0x5f58,0x81)
  poke(unpack(split"0x5600,4,8,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,63,63,63,63,63,63,63,0,0,0,63,63,63,0,0,0,0,0,63,51,63,0,0,0,0,0,51,12,51,0,0,0,0,0,51,0,51,0,0,0,0,0,51,51,51,0,0,0,0,48,60,63,60,48,0,0,0,3,15,63,15,3,0,0,62,6,6,6,6,0,0,0,0,0,48,48,48,48,62,0,99,54,28,62,8,62,8,0,0,0,0,24,0,0,0,0,0,0,0,0,0,12,24,0,0,0,2,0,0,0,0,0,0,0,10,10,0,0,0,0,0,4,10,4,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,1,0,0,0,0,0,54,54,0,0,0,0,0,0,54,127,54,54,127,54,0,8,62,11,62,104,62,8,0,0,51,24,12,6,51,0,0,14,27,27,110,59,59,110,0,12,12,0,0,0,0,0,0,24,12,6,6,6,12,24,0,12,24,48,48,48,24,12,0,0,54,28,127,28,54,0,0,2,7,2,0,0,0,0,0,0,2,1,0,0,0,0,0,0,7,0,0,0,0,0,0,0,0,2,0,0,0,0,0,32,48,24,12,6,3,1,0,7,5,7,0,0,0,0,0,3,2,7,0,0,0,0,0,3,2,6,0,0,0,0,0,7,6,7,0,0,0,0,0,5,7,4,0,0,0,0,0,6,2,3,0,0,0,0,0,1,7,7,0,0,0,0,0,7,4,2,0,0,0,0,0,6,7,7,0,0,0,0,0,7,7,4,0,0,0,0,0,2,0,2,0,0,0,0,0,0,0,12,0,0,12,6,0,4,2,4,0,0,0,0,0,0,0,30,0,30,0,0,0,1,2,1,0,0,0,0,0,3,0,2,0,0,0,0,0,0,30,51,59,59,3,30,0,2,7,5,0,0,0,0,0,3,7,3,0,0,0,0,0,7,1,7,0,0,0,0,0,3,5,3,0,0,0,0,0,7,3,7,0,0,0,0,0,7,3,1,0,0,0,0,0,1,5,7,0,0,0,0,0,5,7,5,0,0,0,0,0,7,2,7,0,0,0,0,0,4,5,6,0,0,0,0,0,5,3,5,0,0,0,0,0,1,1,7,0,0,0,0,0,7,7,5,0,0,0,0,0,3,5,5,0,0,0,0,0,7,5,7,0,0,0,0,0,7,7,1,0,0,0,0,0,2,5,6,0,0,0,0,0,3,7,5,0,0,0,0,0,6,2,3,0,0,0,0,0,7,2,2,0,0,0,0,0,5,5,7,0,0,0,0,0,5,5,2,0,0,0,0,0,5,7,7,0,0,0,0,0,5,2,5,0,0,0,0,0,5,2,2,0,0,0,0,0,3,2,6,0,0,0,0,0,62,6,6,6,6,6,62,0,1,3,6,12,24,48,32,0,62,48,48,48,48,48,62,0,12,30,18,0,0,0,0,0,0,0,0,0,0,0,30,0,12,24,0,0,0,0,0,0,2,7,5,0,0,0,0,0,3,7,3,0,0,0,0,0,7,1,7,0,0,0,0,0,3,5,3,0,0,0,0,0,7,3,7,0,0,0,0,0,7,3,1,0,0,0,0,0,1,5,7,0,0,0,0,0,5,7,5,0,0,0,0,0,7,2,7,0,0,0,0,0,4,5,6,0,0,0,0,0,5,3,5,0,0,0,0,0,1,1,7,0,0,0,0,0,7,7,5,0,0,0,0,0,3,5,5,0,0,0,0,0,7,5,7,0,0,0,0,0,7,7,1,0,0,0,0,0,2,5,6,0,0,0,0,0,3,7,5,0,0,0,0,0,6,2,3,0,0,0,0,0,7,2,2,0,0,0,0,0,5,5,7,0,0,0,0,0,5,5,2,0,0,0,0,0,5,7,7,0,0,0,0,0,5,2,5,0,0,0,0,0,5,2,2,0,0,0,0,0,3,2,6,0,0,0,0,0,56,12,12,7,12,12,56,0,8,8,8,0,8,8,8,0,14,24,24,112,24,24,14,0,0,0,110,59,0,0,0,0,0,0,0,0,0,0,0,0,7,7,7,0,0,0,0,0,85,42,85,42,85,42,85,0,65,99,127,93,93,119,62,0,62,99,99,119,62,65,62,0,60,36,103,0,0,0,0,0,4,12,124,62,31,24,16,0,28,38,95,95,127,62,28,0,34,119,127,127,62,28,8,0,42,28,54,119,54,28,42,0,28,28,62,93,28,20,20,0,8,28,62,127,62,42,58,0,62,103,99,103,62,65,62,0,62,127,93,93,127,99,62,0,24,120,8,8,8,15,7,0,62,99,107,99,62,65,62,0,8,20,42,93,42,20,8,0,12,18,97,0,0,0,0,0,62,115,99,115,62,65,62,0,8,28,127,28,54,34,0,0,127,34,20,8,20,34,127,0,62,119,99,99,62,65,62,0,0,10,4,0,80,32,0,0,76,42,25,0,0,0,0,0,62,107,119,107,62,65,62,0,127,0,127,0,127,0,127,0,85,85,85,85,85,85,85,0"))
end

function _update60()
  -- cpu_flag(0)

  upd_btns()
  if stat(120) then import_synth() end
  old_update60()

  if dev and btnp(4,1) then
    pq("modules",modules)
    pq("#wires",#wires)
    pq("wires[1]",wires[1])
    pq("trks",trks)
    pq("trkp",trkp)
    pq("page",page)
  end
end
function _draw()
  old_draw()
  dev_outline_modules()
  -- dd(print,selectedmod,16,16,7)
  drw_debug()
  if dev_overheat and not cpuok() then pq"!!! overheated :(" end
end

function old_update60()
  --tracker and input
  if tracker_mode then
    tracker()
  else
    while stat(30) do
      stat(31)
    end
  end

  if not tracker_mode then
    if btn(❎) then
      leftbar.oname[13]="on"
      leftbar.o[13]=1
    else
      leftbar.oname[13]="off"
      leftbar.o[13]=-1
    end
    if btn(🅾️) then
      leftbar.oname[14]="on"
      leftbar.o[14]=1
    else
      leftbar.oname[14]="off"
      leftbar.o[14]=-1
    end
    if btn(➡️) then leftbar.o[15]+=.01 end
    if btn(⬅️) then leftbar.o[15]-=.01 end
    leftbar.o[15]=mid(-1,leftbar.o[15],1)
    leftbar.oname[15]=flr(leftbar.o[15]*10)

    if btn(⬆️) then leftbar.o[16]+=.003 end
    if btn(⬇️) then leftbar.o[16]-=.003 end
    leftbar.o[16]=mid(-1,leftbar.o[16],1)
    leftbar.oname[16]=flr(leftbar.o[16]*10)
  end

  -- fill audio buffer
  local len=min(94,1536-stat(108))
  --len=stat(109)-stat(108)
  oscbuf={}

  -- local ww=remap(len,0,200,0,127)
  -- dd(rectfill,0,0,ww,8,5)
  -- pq(len)

  for i=0,len-1 do
    -- cpu_flag()
    if playing then
      play()
    end
    generate()
    if #oscbuf <=46 and i%2==0 then
      add(oscbuf,modules[1].i[1])
    end
    poke(0x4300+i,(modules[1].i[1]+1)*127.5)
  end
  serial(0x808,0x4300,len)


  if mbtn(0) then
    -- top right menu buttons?
    -- else, right-click menu?
    -- else, module click?
    -- module release (complicated conditions)
    if mx>=96 and my<8 and mbtnp(0) then
      if mx<104 then
        rec=not rec
        if rec then
          extcmd('audio_rec')
        else
          extcmd('audio_end')
        end
      elseif mx<112 then
        pgmode+=1
        pgmode%=3
      elseif mx<120 then
        playing=not playing
        if not playing then
          pause()
        else
          if pgmode==0 then
            pg=1
          end
          trkp=0
          if #page==0 then
            addpage()
          end
          for x=1,11,2 do
            local n=page[pg][(x+1)/2][1][1]
            if n>-2 then
              leftbar.o[x]=n
              leftbar.o[x+1]=1
            else
              leftbar.o[x+1]=-1
            end
          end
        end
      else
        tracker_mode=not tracker_mode
        if tracker_mode then
          if #page==0 then
            addpage()
          end
        end
      end
    else
      if rcmenu==nil then
        if not tracker_mode then
          moduleclick()
        else
          modulerelease()
        end
      else
        if mx>=rcp[1] and
              mx<=rcp[1]+24 and
              my>=rcp[2] and
              my<=rcp[2]+#rcmenu*5-1 then
          local sel=mid(ceil((my-rcp[2]+1)/5),1,#modmenu)
          if rcmenu!=modmenu and sel>1 then
            modules[selectedmod]:propfunc(sel-1)
          else
            rcfunc[sel]()
          end
          if rcmenu==modmenu then
            modules[#modules].x=rcp[1]-10
            modules[#modules].y=rcp[2]-3
          end
          rcmenu=nil
        else
          rcmenu=nil
        end
      end
    end
  else
    modulerelease()
  end
  if mbtnp(1) then
    --if on module, rcmenu = id
    if not tracker_mode then
      selectedmod=inmodule(mx,my)
      if selectedmod>0 then
        rcmenu={"delete"}
        rcfunc={delmod}
        if modules[selectedmod].prop then
          for x=1,#modules[selectedmod].prop do
            add(rcmenu,modules[selectedmod].prop[x])
          end
        end
      else
        rcmenu=modmenu
        rcfunc=modmenufunc
      end
    else

    end
    rcp={mx,my}
    rcp[2]=min(rcp[2],127-#rcmenu*5)
  end
end

function generate()
  for mod in all(modules) do
    mod:step()
  end
  for wire in all(wires) do
    wire[3].i[wire[4]]=wire[1].o[wire[2]]
  end
end