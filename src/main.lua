function _init()
  if not dev then
    toast"warning: loud! turn down volume"
  end

  cartdata("wwmodular-1")
  projid=dget(0)+1

  speaker=new_speaker()
  leftbar=new_leftbar()

  -- palette
  pal(split"129,5,134,15,12,1,7,8,4,9,11,6,13,131,2",1)
  palt(0,false)
  palt(14,true)
  if dev_palpersist then poke(0x5f2e,1) end

  -- mouse+kb
  poke(0x5f2d,0x1)

  -- font; see also font.lua
  poke(0x5f58,0x81)

  ini_patchmode()
end

function menuitems()
  menuitem(1,"export",export_patch)
  if upd==upd_samplemode then
    menuitem(2,"return",ini_patchmode)
  else
    menuitem(2,"manage samples",ini_samplemode)
  end
  menuitem(3,"---",function() return true end) --visual separation from p8 menu
end

function _update60()
  upd_mouse()

  upd_droppedfile()

  upd()

  -- fill audio buffer
  local len=min(94,1536-stat(108))
  oscbuf={}

  for i=0,len-1 do
    -- play
    if playing then
      play()
    end

    -- generate samples
    for mod in all(modules) do
      if mod.step then mod:step() end
    end

    -- visualize
    local speaker_inp=mem[speaker.inp]/0x.0002*0x.0002 --mid(mem[speaker.inp],-1,0x.ffff)
    if hqmode and #oscbuf <=46 and i%2==0 then
      add(oscbuf,speaker_inp)
    end
    poke(0x4300+i,(speaker_inp+1)*127.5)
  end
  serial(0x808,0x4300,len)

  if dev and btnp(4,1) and not upd~=upd_trackmode then
    -- debugmod(modules[held])
    hqmode=not hqmode
    toast(qq("hq?",hqmode))
  end
end
function _draw()
  drw()

  --rcmenu
  if rcmenu!=nil then
    --local rch=#rcmenu*4
    rectwh(rcpx-1,rcpyc-1,27,2+#rcmenu*5,13)
    for x=0,#rcmenu-1 do
      rectfillwh(rcpx,rcpyc+x*5,25,5,(x%2*5)+1)
      ?rcmenu[x+1],rcpx+1,rcpyc+1+5*x,7
    end
  end

  --mouse
  spr(0,mx,my)
  cpuusage=stat(1)

  drw_droppedfile()

  do_toast()
  -- print("\#0\15"..stat(0),0,0,7) --mem usage
end

function draw_toprightmenu()
  spr(rec and 8 or 7,96,0)
  spr(9+pgmode,104,0)
  spr(playing and 12 or 13,112,0)
  spr(upd==upd_trackmode and 15 or 14,120,0)
end
