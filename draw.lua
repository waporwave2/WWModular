--draw

function old_draw()
  if not tracker_mode then
    --module mode
    cls(1)
    --osc
    rectfill(80,105,126,126,0)
    rect(79,104,127,127,6)
    for x=1,#oscbuf do
      local rind=min(x+1,#oscbuf)
      local lval=oscbuf[x]
      local rval=oscbuf[rind]
      lval=((lval+1)%2.01)-1
      rval=((rval+1)%2.01)-1
      line(79+x,116-lval*10.9,min(80+x,125),116-rval*10.9,11)
    end
    ?"cpu:"..flr(stat(1)*100)/100,81,106,10

    --modules
    for mod in all(modules) do
      local h=max(#mod.o,#mod.i)

      rectfill(mod.x-1,mod.y,
        mod.x+27,
        mod.y+8*h+5,
        2)
      rectfill(mod.x,mod.y-1,
        mod.x+28,
        mod.y+8*h+4,
        4)
      rectfill(mod.x,mod.y,
        mod.x+27,
        mod.y+8*h+4,
        3)
      ?mod.name,mod.x+1,mod.y+1,0
      for x=0,#mod.i-1 do
        spr(2,mod.x+1,mod.y+5+8*x)
        ?mod.iname[x+1],mod.x+1,mod.y+9+8*x,0
      end
      for x=0,#mod.o-1 do
        spr(1,mod.x+16,mod.y+5+8*x)
        ?mod.oname[x+1],mod.x+16,mod.y+9+8*x,0
      end
    end

    if con!=nil then
      local p=iop(con,conid,conin)
      line(mx,my,p[1],p[2],concol)
    end

    for wire in all(wires) do
      local ip = iop(wire[3],wire[4],true)
      local op = iop(wire[1],wire[2],false)
      line(ip[1],ip[2],op[1],op[2],wire[5])
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
    print("waporware modular\na dsp synth toy.\ndesigned and coded by:\nwaporwave\noptimized by:\npancelor"..pulse("",.5,"█",.5),4,3,11)
    print("octave:"..oct.." page:"..pg,4,28,11)

    ?"t1  t2  t3  t4  t5  t6",6,34,0
    rect(1,38,98,119,2)


    for x=0,5 do
      ?pgtrg[x+1]and"trg"or"gat",x*16+4,122,0
      --trg gat buttons
      line(17+x*16,120,17+x*16,125,4)
      line(2+x*16,121,2+x*16,126,2)
      line(2+x*16,126,16+x*16,126,2)
      line(3+x*16,120,16+x*16,120,4)
      for y=0,15 do
        rectfill(x*16+2,y*5+39,x*16+17,y*5+43,(trks[1]==x and trks[2]==y)and 13or((y+x)%2)*5+1)
        local ch=page[pg][x+1][y+1][2]
        ?ch,x*16+3,y*5+40,0
      end
    end
    line(1,flr(trkp)*5+39,1,flr(trkp)*5+43,10)
  end
  --rcmenu
  if rcmenu!=nil then
    --local rch=#rcmenu*4
    rect(rcp[1]-1,rcp[2]-1,rcp[1]+25,rcp[2]+#rcmenu*5,13)
    for x=0,#rcmenu-1 do
      rectfill(rcp[1],rcp[2]+x*5,rcp[1]+24,rcp[2]+x*5+4,(x%2*5)+1)
      ?rcmenu[x+1],rcp[1]+1,rcp[2]+1+5*x,7
    end
  end

  --top-right menu
  spr(7+(rec and 1 or 0),96,0)
  spr(9+pgmode,104,0)
  spr(13-(playing and 1 or 0),112,0)
  spr(14+(tracker_mode and 1 or 0),120,0)

  --mouse
  spr(0,mx,my)
end
