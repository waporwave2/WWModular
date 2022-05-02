--tracker
--probably figure out frequency
-- -1 to 1 to hz

--optimization!
--wires seem to cause issues
--try having wires attached to
--modules instead, then they
--send output directly, isntead
--of searching
local lkeys={z={-0.937505972289,1},
s={-0.933779264214,2},
x={-0.929842331581,3},
d={-0.925676063067,4},
c={-0.921261347348,5},
v={-0.916579073101,6},
g={-0.911610129001,7},
b={-0.90635451505,8},
h={-0.900793119924,9},
n={-0.894887720975,10},
j={-0.888638318204,11},
m={-0.882006688963,12},
q={-0.874992833254,13},
w={-0.859684663163,15},
e={-0.842503583373,17},
r={-0.833139034878,18},
t={-0.8127090301,20},
y={-0.789775441949,22},
u={-0.76403248925,24},
i={-0.750004777831,25},
o={-0.719388437649,27},
p={-0.68502627807,29}
}

local nkeys={nil,
{-0.867558528428,14},
{-0.851352126135,16},
nil,
{-0.823220258003,19},
{-0.801567128524,21},
{-0.777276636407,23},
nil,
{-0.73513616818,28},
{-0.702704252269,30}}

local keyname={"c","c+","d","d+","e","f","f+","g","g+","a","a+","b"}

function tracker()
  if btnp(➡️) then trks[1]+=1 end
  if btnp(⬅️) then trks[1]-=1 end
  if btnp(⬇️) then trks[2]+=1 end
  if btnp(⬆️) then trks[2]-=1 end
  trks[1]%=6
  trks[2]%=16

  --gate and other buttons
  if mbtnp(0) then
    if mx>1and mx<98and
      my>119and my<127 then
      local tk=(mx-2)\16+1
      tk=mid(1,tk,6)
      pgtrg[tk]=not pgtrg[tk]
    end

    if mx>95and mx<127and
      my>9and my<33 then
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
  end

  --key2note
  while stat(30) do
    local n=stat(31)
    if n=="\b"then
      for x=trks[2],15 do
        page[pg][trks[1]+1][x]=page[pg][trks[1]+1][x+1]
      end
      page[pg][trks[1]+1][16]={-2,"--"}
      trks[2]-=1
      trks[2]%=16
    end
    if n=="\r" or n=="p" then
      poke(0x5f30,1) --prevent pause
      if n=="\r" then
        for x=16,trks[2]+2,-1 do
          page[pg][trks[1]+1][x]=page[pg][trks[1]+1][x-1]
        end
        page[pg][trks[1]+1][trks[2]+1]={-2,"--"}
        trks[2]+=1
        trks[2]%=16
      end
    end
    if n=="\t" then
      trks[1]+=1
      trks[1]%=6
    end
    k=lkeys[n] or nkeys[tonum(n)]
    if k then
      page[pg][trks[1]+1][trks[2]+1]=key2note(k)
      trks[2]+=1
    end
  end
end

function key2note(k)
  local f=(k[1]+1)*(2^oct)-1
  local nn=keyname[(k[2]-1)%12+1]..ceil(k[2]/12)+oct-1
  -- frequency, draw name, key id
  return {f,nn,k[2]}
end
function import_note(id)
  if id==0 then
    return {-2,"--",0}
  end
  for _,k in pairs(lkeys) do
    if k[2]==id then return key2note(k) end
  end
  for ii=0,9 do
    local k=nkeys[ii]
    if k and k[2]==id then return key2note(k) end
  end
end

function play()
  local inc=(modules[1].i[2]+1)/600
  trkp+=inc
  if trkp>16 then
    if pgmode==0 then
      pg+=1
      pg=(pg-1)%(#page)+1
    elseif pgmode==2 then
      pg-=1
      pg=(pg-1)%(#page)+1
    end
  end
  trkp%=16
  if flr(trkp-inc*2)!=flr(trkp) then
    for x=1,6 do
      if pgtrg[x] then
        leftbar.o[x*2]=-1
      end
    end
  end
  if flr(trkp-inc)!=flr(trkp) then
    for x=1,11,2 do
      local n=page[pg][(x+1)/2][flr(trkp)+1][1]
      if n>-2 then
        leftbar.o[x]=n
        leftbar.o[x+1]=1
      else
        leftbar.o[x+1]=-1
      end
    end
  end

end

function pause()
  for x=2,12,2 do
    leftbar.o[x]=-1
  end
end

function addpage()
  local newp={}

  for r=1,6 do
    add(newp,{})
    for c=1,16 do
      add(newp[#newp],import_note(0))
    end
  end
  add(page,newp)
end

function delpage(ii)
  if #page>1 then
    deli(page,ii)
  end
end
