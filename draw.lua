--draw

function old_draw()
  if not tracker_mode then
    --module mode
    cls(1)
    if web_version then
      ?"audio quality suffers on\nweb. for best experience,\nplease download on pc.",22,50,6
    end
    --osc
    rectfill(80,105,126,126,0)
    if hqmode then
      rect(79,104,127,127,6)

      line(11)
      for lind,lval in ipairs(oscbuf) do
        lval=((lval+1)%2.01)-1
        local y=116-lval*10.9
        if lval<0 then y=ceil(y) end
        line(79+lind,y)
      end
    end
    local cpustr=tostr(cpuusage\.001/1000)
    while #cpustr<5 do cpustr..="0" end --rightpad
    ?"cpu:"..cpustr,81,106,10

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
      drawwire(mx,my,px,py,concol)
    end

    for wire in all(wires) do
      local ipx,ipy = iop(wire[3],wire[4],true)
      local opx,opy = iop(wire[1],wire[2],false)
      drawwire(ipx,ipy,opx,opy,wire[5])
    end
  else
    --tracker_mode
    cls(3)

    --top right menu
    --rectfill(95,0,128,8,0)
    sspr(0,8,32,64,95,9)
    sspr(96,8,32,120,96,8)
    ?"oc- oc+",98,12,0
    ?"pg- pg+",98,20,0
    ?"pg< pg>",98,28,0

    --info
    rectfill(2,1,93,32,6)
    rectfill(3,2,92,31,0)
    print("waporware modular\na dsp synth toy.\ndesign,code: waporwave\n  fast code: pancelor"..pulse("",.5,"█",.5),4,3,11)
    print("octave:"..oct.." page:"..pg,4,28,11)

    ?"t1  t2  t3  t4  t5  t6",6,34,0
    rect(1,38,98,119,2)


    for x=0,5 do
      ?pgtrg[x+1]and"trg"or"gat",x*16+4,122,0
      --trg gat buttons
      rectwh(17+x*16,120,1,6,4)
      rectwh(2+x*16,121,1,6,2)
      rectwh(2+x*16,126,15,1,2)
      rectwh(3+x*16,120,14,1,4)
      for y=0,15 do
        rectfillwh(x*16+2,y*5+39,16,5,(trkx==x and trky==y)and 13or((y+x)%2)*5+1)
        local ch=page[pg][x+1][y+1][2]
        ?ch,x*16+3,y*5+40,0
      end
    end
    rectwh(1,flr(trkp)*5+39,1,5,10)
  end
  --rcmenu
  if rcmenu!=nil then
    --local rch=#rcmenu*4
    rectwh(rcpx-1,rcpyc-1,27,2+#rcmenu*5,13)
    for x=0,#rcmenu-1 do
      rectfillwh(rcpx,rcpyc+x*5,25,5,(x%2*5)+1)
      ?rcmenu[x+1],rcpx+1,rcpyc+1+5*x,7
    end
  end

  --top-right menu
  spr(7+(rec and 1 or 0),96,0)
  spr(9+pgmode,104,0)
  spr(13-(playing and 1 or 0),112,0)
  spr(14+(tracker_mode and 1 or 0),120,0)

  --mouse
  spr(0,mx,my)
  cpuusage=stat(1)
end
