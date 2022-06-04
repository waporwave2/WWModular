--tracker
--probably figure out frequency
-- -1 to 1 to hz

--optimization!
--wires seem to cause issues
--try having wires attached to
--modules instead, then they
--send output directly, isntead
--of searching
local keys={}
for dat in all(split([[z,-0.937505972289,1
s,-0.933779264214,2
x,-0.929842331581,3
d,-0.925676063067,4
c,-0.921261347348,5
v,-0.916579073101,6
g,-0.911610129001,7
b,-0.90635451505,8
h,-0.900793119924,9
n,-0.894887720975,10
j,-0.888638318204,11
m,-0.882006688963,12
q,-0.874992833254,13
w,-0.859684663163,15
e,-0.842503583373,17
r,-0.833139034878,18
t,-0.8127090301,20
y,-0.789775441949,22
u,-0.76403248925,24
i,-0.750004777831,25
o,-0.719388437649,27
p,-0.68502627807,29
2,-0.867558528428,14
3,-0.851352126135,16
5,-0.823220258003,19
6,-0.801567128524,21
7,-0.777276636407,23
9,-0.73513616818,28
0,-0.702704252269,30
]],"\n")) do
  local name,fr,id=unpacksplit(dat)
  keys[tostr(name)]={fr,id}
end

local keyname=split"c,c+,d,d+,e,f,f+,g,g+,a,a+,b"

function tracker()
  trkx+=tonum(btnp(➡️))-tonum(btnp(⬅️))
  trkx%=6
  trky+=tonum(btnp(⬇️))-tonum(btnp(⬆️))
  trky%=16

  --gate and other buttons
  if topmenu_input() then
    --don't fall through
  elseif mbtnp(0) and rect_collide(2,120,96,7,mx,my) then
    local tk=(mx-2)\16+1
    tk=mid(1,tk,6)
    pgtrg[tk]=not pgtrg[tk]
  elseif mbtnp(0) and rect_collide(96,10,31,23,mx,my) then
    local y=(my-10)\8
    if mx<=111 then
      if y==0 then
        oct-=1
      elseif y==1 then
        delpage(pg)
        pg-=1
        pg=(pg-1)%(#page)+1
      else
        pg-=1
        pg=(pg-1)%(#page)+1
      end
    else
      if y==0 then
        oct+=1
      elseif y==1 then
        addpage()
        pg+=1
      else
        pg+=1
        pg=(pg-1)%(#page)+1
      end
    end
    oct=mid(0,oct,4)
  end

  --key2note
  while stat(30) do
    local n=stat(31)
    if n=="\b"then
      for x=trky,15 do
        page[pg][trkx+1][x]=page[pg][trkx+1][x+1]
      end

      page[pg][trkx+1][16]=import_note(0,oct)
      trky-=1
      trky%=16
    end
    if n=="\r" or n=="p" then
      poke(0x5f30,1) --prevent pause
      if n=="\r" then
        for x=16,trky+2,-1 do
          page[pg][trkx+1][x]=page[pg][trkx+1][x-1]
        end

        page[pg][trkx+1][trky+1]=import_note(0,oct)
        trky+=1
        trky%=16
      end
    end
    if n=="\t" then
      trkx+=1
      trkx%=6
    end
    local k=keys[n]
    if k then
      page[pg][trkx+1][trky+1]=key2note(k,oct)
      if not playing then
        -- write to t1, t2, t3, etc
        mem[leftbar[trkx+1]]=key2note(k,oct)[1]
      end
      trky+=1
      trky%=16
    end
  end
end

-- function check_page(flag)
--   local sheet=page[pg]
--   assert(#sheet==6,flag)
--   for xx,column in ipairs(sheet) do
--     assert(#column==16,flag)
--     for yy,note in ipairs(column) do
--       assert(note and note[3],quote(flag,xx,yy))
--     end
--   end
-- end

function key2note(k,octave)
  local f=(k[1]+1)*(2^octave)-1
  local nn=keyname[(k[2]-1)%12+1]..ceil(k[2]/12)+octave-1
  -- frequency, draw name, save data
  assert(k[2]<256,"need to change octave encoding")
  return {f,nn,k[2]+octave*256}
end
function import_note(id,octave)
  if id==0 then return split"-2,--,0" end
  for _,k in pairs(keys) do
    if k[2]==id then return key2note(k,octave) end
  end
  assert(nil,quote(id,octave))
end

-- advance the tracker and update leftbar's outputs
function play()
  local inc=mid(0,1,(mem[speaker.spd]+1)/600)
  trkp+=inc
  if trkp>=16 then
    if pgmode==0 then
      pg+=1
      pg=(pg-1)%(#page)+1
    elseif pgmode==2 then
      pg-=1
      pg=(pg-1)%(#page)+1
    end
    trkp-=16
  end
  local flr_trkp=trkp\1
  if flr(trkp-inc)!=flr_trkp or trkp-inc==0 then
    tracker_senddata(flr_trkp+1,1)
  else
    for ix=1,6 do
      if pgtrg[ix] then
        -- write to gat1, gat2, gat3, etc
        mem[leftbar[ix+6]]=-1
      end
    end
  end
end

-- pancelor: I'm not sure exactly what to call this
function tracker_senddata(row,col)
  for ix=1,6 do
    local n=page[pg][ix][row][col]
    if n>-2 then
      mem[leftbar[ix]]=n
      mem[leftbar[ix+6]]=1
    else
      mem[leftbar[ix+6]]=-1
    end
  end
end

function pause()
  for ix=1,6 do
    mem[leftbar[ix+6]]=-1
  end
end

function addpage()
  local newp=add(page,{})
  for r=1,6 do
    local pg=add(newp,{})
    for c=1,16 do
      add(pg,import_note(0,oct))
    end
  end
end

function delpage(ii)
  if(#page>1)deli(page,ii)
end
