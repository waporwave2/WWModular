--patch mode

-- returns whether any input happened
-- note: this only deals with choosing an option
-- from an existing rcmenu; creating rcmenu
-- is handled separately
function rcmenu_input()
  if mbtn(0) and rcmenu then
    if rect_collide(rcpx,rcpyc,25,#rcmenu*5,mx,my) then
      local sel=mid(ceil((my-rcpyc+1)/5),1,#modmenu)
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
      return true
    else
      rcmenu=nil
    end
  end
end

-- returns whether any input happened
function topmenu_input()
  if mbtnp(0) and mx>=96 and my<8 then
    if mx<104 then
      rec=not rec
      if rec then
        if web_version then
          rec=false
          toast"can't record in web version"
        else
          local str="recording"

          if cpuusage>.8 then
            str..="; switch to lq mode"
            hqmode=false
          end
          toast(str)
          extcmd'audio_rec'
        end
      else
        hqmode=true
        toast"recording saved to desktop"
        extcmd'audio_end'
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
      end
    else
      if upd==upd_trackmode then
        ini_patchmode()
      else --elseif upd==upd_patchmode then
        ini_trackmode()
      end
    end
    return true
  end
end

function ini_patchmode()
  upd,drw=upd_patchmode,drw_patchmode
  menuitems()
end

function upd_patchmode()
  eat_keyboard() --eat input while not in tracker mode

  mem[leftbar.btx]=btn(❎) and 1 or -1
  mem[leftbar.btz]=btn(🅾️) and 1 or -1

  -- LMB
  if rcmenu_input() then
    -- don't fall through if rcmenu used the click
  elseif topmenu_input() then
    -- don't fall through if topmenu used the click
  elseif module_custom_input() then
    -- don't fall through
  elseif mbtn(0) then
    moduleclick()
  else
    modulerelease()
  end

  -- RMB
  if mbtnp(1) then
    --if on module, rcmenu = id
    selectedmod=inmodule(mx,my)
    if selectedmod>0 then
      rcmenu={"delete"}
      rcfunc={delmod}
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
    rcpy=my
    rcpyc=min(my,127-#rcmenu*5) --stay onscreen
  end
end

function drw_patchmode()
  cls(1)
  if web_version then
    ?"audio quality suffers on\nweb. for best experience,\nplease download on pc.",22,50,6
  end
  --osc
  rectfill(80,104,126,126,0)
  if hqmode then
    rect(79,103,127,127,6)

    line(11)
    for lind,lval in ipairs(oscbuf) do
      lval=(lval+1)%2.01 - 1
      local y=115-lval*10.9
      if lval<0 then y=ceil(y) end
      line(79+lind,y)
    end
  end
  local cpustr=tostr(cpuusage\.001/1000)
  while #cpustr<5 do cpustr..="0" end --rightpad
  ?"cpu:"..cpustr,81,105,10

  --modules
  for mod in all(modules) do
    local inum,onum=#mod.iname,#mod.oname
    local spc=5
    local h=spc*max(inum,onum)+6

    if hqmode then
      rectwh(mod.x-1,mod.y,35,h,2)
      rectwh(mod.x,mod.y-1,35,h,4)
    end
    rectfillwh(mod.x,mod.y,34,h-1,3)
    ?mod.name,mod.x+1,mod.y+1,0
    for ix=1,inum do
      if hqmode then
        spr(2,mod.x+1,mod.y+spc*ix+1,3/8,3/8)
      else
        pset(mod.x+2,mod.y+spc*ix+2,7)
      end
      ?(mod.iname_user or mod.iname)[ix],mod.x+5,mod.y+spc*ix+1,0
    end
    for ix=1,onum do
      if hqmode then
        spr(1,mod.x+18,mod.y+spc*ix+1,3/8,3/8)
      else
        pset(mod.x+19,mod.y+spc*ix+2,6)
      end
      ?(mod.oname_user or mod.oname)[ix],mod.x+22,mod.y+spc*ix+1,0
    end
    
    if mod.custom_render then
      mod:custom_render()
    end
  end

  if con then
    local px,py=iop(con,conid,conin)
    fillp_from_addr(conin and 0 or nth_outaddr(con,conid))
    drawwire(mx,my,px,py,concol)
  end

  for wire in all(wires) do
    local ipx,ipy = iop(wire[3],wire[4],true)
    local opx,opy = iop(wire[1],wire[2],false)
    fillp_from_addr(nth_outaddr(wire[1],wire[2]))
    drawwire(ipx,ipy,opx,opy,wire[5])
  end
  fillp()

  draw_toprightmenu()
end
