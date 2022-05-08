local modmenu={}
local modmenufunc={}
local modprop={}
local modpropfunc={}

--tracker
local trkx=0 --position
local trky=0 --position
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

local projid=0
local oscbuf={}
local modules={}
local wires={}
-- each wire is {from_mod,from_port_ix, to_mod,to_port_ix, value}
local held -- module index we're holding right now
local con -- module we're dragging a wire from right now
local conin=true
local conid=0 -- which port on con we're interacting with
local concol=3
local rcmenu
local rcfunc
local selectedmod=-1
local rcpx=0
local rcpy=0
local anchorx=0 --grab offset
local anchory=0 --grab offset
local io_override=nil --custom module interaction
local hqmode=true --performance mode for rendering --so far saved about .03 cpu lol
local cpuusage=0

local mem={[0]=0} -- memory for module value propagation
local speaker -- reference to a module
local leftbar -- reference to a module

function cpuok()
 return stat(1)<1 and stat(7)==60
end

function _init()
  toast"warning, loud! turn down volume"
  --add modules to menu
  cartdata("wwmodular-1")
  projid=dget(0)+1

  speaker=new_speaker()
  leftbar=new_leftbar()

  menuitem(1,"export",export_synth)
  if dev then menutrace(2) end

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
  poke(unpack(split"0x5600,4,8,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,63,63,63,63,63,63,63,0,0,0,63,63,63,0,0,0,0,0,63,51,63,0,0,0,0,0,51,12,51,0,0,0,0,0,51,0,51,0,0,0,0,0,51,51,51,0,0,0,0,48,60,63,60,48,0,0,0,3,15,63,15,3,0,0,62,6,6,6,6,0,0,0,0,0,48,48,48,48,62,0,99,54,28,62,8,62,8,0,0,0,0,24,0,0,0,0,0,0,0,0,0,12,24,0,0,0,2,0,0,0,0,0,0,0,10,10,0,0,0,0,0,4,10,4,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,1,0,0,0,0,0,54,54,0,0,0,0,0,0,54,127,54,54,127,54,0,8,62,11,62,104,62,8,0,0,51,24,12,6,51,0,0,14,27,27,110,59,59,110,0,12,12,0,0,0,0,0,0,24,12,6,6,6,12,24,0,12,24,48,48,48,24,12,0,0,2,0,0,0,0,0,0,2,7,2,0,0,0,0,0,0,2,1,0,0,0,0,0,0,7,0,0,0,0,0,0,0,0,2,0,0,0,0,0,32,48,24,12,6,3,1,0,7,5,7,0,0,0,0,0,3,2,7,0,0,0,0,0,3,2,6,0,0,0,0,0,7,6,7,0,0,0,0,0,5,7,4,0,0,0,0,0,6,2,3,0,0,0,0,0,1,7,7,0,0,0,0,0,7,4,2,0,0,0,0,0,6,7,7,0,0,0,0,0,7,7,4,0,0,0,0,0,2,0,2,0,0,0,0,0,0,0,12,0,0,12,6,0,4,2,4,0,0,0,0,0,0,0,30,0,30,0,0,0,1,2,1,0,0,0,0,0,3,0,2,0,0,0,0,0,0,30,51,59,59,3,30,0,2,7,5,0,0,0,0,0,3,7,3,0,0,0,0,0,7,1,7,0,0,0,0,0,3,5,3,0,0,0,0,0,7,3,7,0,0,0,0,0,7,3,1,0,0,0,0,0,1,5,7,0,0,0,0,0,5,7,5,0,0,0,0,0,7,2,7,0,0,0,0,0,4,5,6,0,0,0,0,0,5,3,5,0,0,0,0,0,1,1,7,0,0,0,0,0,7,7,5,0,0,0,0,0,3,5,5,0,0,0,0,0,7,5,7,0,0,0,0,0,7,7,1,0,0,0,0,0,2,5,6,0,0,0,0,0,3,7,5,0,0,0,0,0,6,2,3,0,0,0,0,0,7,2,2,0,0,0,0,0,5,5,7,0,0,0,0,0,5,5,2,0,0,0,0,0,5,7,7,0,0,0,0,0,5,2,5,0,0,0,0,0,5,2,2,0,0,0,0,0,3,2,6,0,0,0,0,0,62,6,6,6,6,6,62,0,1,3,6,12,24,48,32,0,62,48,48,48,48,48,62,0,12,30,18,0,0,0,0,0,0,0,0,0,0,0,30,0,12,24,0,0,0,0,0,0,2,7,5,0,0,0,0,0,3,7,3,0,0,0,0,0,7,1,7,0,0,0,0,0,3,5,3,0,0,0,0,0,7,3,7,0,0,0,0,0,7,3,1,0,0,0,0,0,1,5,7,0,0,0,0,0,5,7,5,0,0,0,0,0,7,2,7,0,0,0,0,0,4,5,6,0,0,0,0,0,5,3,5,0,0,0,0,0,1,1,7,0,0,0,0,0,7,7,5,0,0,0,0,0,3,5,5,0,0,0,0,0,7,5,7,0,0,0,0,0,7,7,1,0,0,0,0,0,2,5,6,0,0,0,0,0,3,7,5,0,0,0,0,0,6,2,3,0,0,0,0,0,7,2,2,0,0,0,0,0,5,5,7,0,0,0,0,0,5,5,2,0,0,0,0,0,5,7,7,0,0,0,0,0,5,2,5,0,0,0,0,0,5,2,2,0,0,0,0,0,3,2,6,0,0,0,0,0,56,12,12,7,12,12,56,0,8,8,8,0,8,8,8,0,14,24,24,112,24,24,14,0,0,0,110,59,0,0,0,0,0,0,0,0,0,0,0,0,7,7,7,0,0,0,0,0,85,42,85,42,85,42,85,0,65,99,127,93,93,119,62,0,62,99,99,119,62,65,62,0,60,36,103,0,0,0,0,0,4,12,124,62,31,24,16,0,28,38,95,95,127,62,28,0,34,119,127,127,62,28,8,0,42,28,54,119,54,28,42,0,28,28,62,93,28,20,20,0,8,28,62,127,62,42,58,0,62,103,99,103,62,65,62,0,62,127,93,93,127,99,62,0,24,120,8,8,8,15,7,0,62,99,107,99,62,65,62,0,8,20,42,93,42,20,8,0,12,18,97,0,0,0,0,0,62,115,99,115,62,65,62,0,8,28,127,28,54,34,0,0,127,34,20,8,20,34,127,0,62,119,99,99,62,65,62,0,0,10,4,0,80,32,0,0,76,42,25,0,0,0,0,0,62,107,119,107,62,65,62,0,127,0,127,0,127,0,127,0,85,85,85,85,85,85,85,0"))

  trace=nop
  trace_frame=nop
end

function menutrace(menuix)
  menuitem(menuix,trace==_trace and "∧trace stop" or "∧trace start",function()
    if trace==_trace then
      trace_stop()
    else
      trace_start()
    end
    menutrace()
  end)
end

function _update60()
  trace"_update60"

  -- 50->31
  local arr={}
  for i=1,50 do
    trace("i"..i)
    for j=1,50 do
      if arr[i]==arr[j] then
        x=1
      end
    end
    trace""
  end

  trace""
end
function _draw()
  trace"_draw"

  -- 50->18
  for i=1,21 do
    trace("cls"..i)
    cls()
    trace""
  end

  trace""
  trace_frame()
end

--[[
prediction:
- p8: 100%
- _update60: 19%
- _draw: 32%
- cls1: 1.5%
- cls2: 1.5%
- ...
- cls21: 1.5%

questions:
- why is _update60 so small? 10%
- why does draw have sys happening? seems like it's doubling the cls sys...
]]

-- function _update60()
--   bench_open"_update60"

--   upd_btns()
--   if stat(120) then import_synth() end
--   old_update60()

--   if dev and btnp(4,1) then
--     toast("see console")
--     debugmod(modules[held])
--   end
--   bench_close()
-- end
-- function _draw()
--   bench_open"_draw"
--   old_draw()
--   do_toast()
--   drw_debug()
--   if dev_overheat and not cpuok() then pq"!!! overheated :(" end
--   bench_close()
-- end

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
    mem[leftbar.btx]=btn(❎) and 1 or -1
    mem[leftbar.btz]=btn(🅾️) and 1 or -1
  end

  -- fill audio buffer
  local len=min(94,1536-stat(108))
  --len=stat(109)-stat(108)
  oscbuf={}

  bench_open"samples"
  count1=0
  for i=0,len-1 do
    -- play
    if playing then
      bench_open"play"
      play()
      bench_close()
    end

    -- generate samples
    bench_open"generate"
    local at=stat(1)
    for mod in all(modules) do
      if mod.step then mod:step() end
    end
    local bt=stat(1)
    count1+=bt-at
    bench_close()

    -- visualize
    if hqmode and #oscbuf <=46 and i%2==0 then
      add(oscbuf,mem[speaker.inp])
    end
    poke(0x4300+i,(mem[speaker.inp]+1)*127.5)
  end
  -- bench_open"serial"
  serial(0x808,0x4300,len)
  -- bench_close()
  bench_close() --samples
  pq(count1)


  if mbtn(0) then
    -- top right menu buttons?
    -- else, right-click menu?
    -- else, module click?
    -- module release (complicated conditions)
    if mx>=96 and my<8 and mbtnp(0) then
      if mx<104 then
        rec=not rec
        if rec then
          local str="recording"

          if cpuusage>.8 then
            str..="; switch to lq mode"
            hqmode=false
          end
          toast(str)
          extcmd('audio_rec')
        else
          hqmode=true
          toast("recording saved to pc")
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
          tracker_senddata(1,1)
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
        if not tracker_mode and not io_override then
          moduleclick()
        else
          modulerelease()
        end
      else
        if mx>=rcpx and
              mx<=rcpx+24 and
              my>=rcpy and
              my<=rcpy+#rcmenu*5-1 then
          local sel=mid(ceil((my-rcpy+1)/5),1,#modmenu)
          if rcmenu!=modmenu and sel>1 then
            modules[selectedmod]:propfunc(sel-1)
          else
            rcfunc[sel]()
          end
          if rcmenu==modmenu then
            modules[#modules].x=rcpx-10
            modules[#modules].y=rcpy-3
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
        -- if dev then
        --   add(rcmenu,"debug")
        --   add(rcfunc,debugmod)
        -- end
        if modules[selectedmod].prop then
          for pr in all(modules[selectedmod].prop) do
            add(rcmenu,pr)
          end
        end
      else
        rcmenu=modmenu
        rcfunc=modmenufunc
      end
      rcpx=mx
      rcpy=min(my,127-#rcmenu*5) --stay onscreen
    end
  end

  for mod in all(modules) do
    if mod.custom_input then
      mod:custom_input()
    end
  end
end
