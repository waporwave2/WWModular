--[[
# benchmark.lua

various tools for performance benchmarking

dependencies:
- leftpad
]]

-- bench usage:
-- - set bench_open and bench_close to no-op functions inside _init()
-- - call bench_start()/bench_stop() to start/stop benchmarking
-- - call bench_begin before / after code to profile. nest them!
-- - open the file in sublime; run the "line endings: unix" command
-- - upload the output file (pyroscope.p8l) to https://flamegraph.com/
function bench_start()
  -- bench is a map of name=>{total,sys,isopen} tuples (stat 1 and stat 2)
  -- the stat values are added to when re-opened
  -- bench_scope is a stack of ;-joined names
  --  e.g. {"foo","foo;bar","foo;bar;baz"}
  bench={}
  bench_scope={"p8"}
  bench_open=_bench_open
  bench_close=_bench_close
end
function bench_stop( filename)
  bench_open=nop
  bench_close=nop
  assert(#bench_scope==1,"unclosed bench: "..deli(bench_scope))

  local bench_filename=filename or "pyroscope.p8l"
  local firstline=true
  for name,dat in pairs(bench) do
    local tot,sys,isopen=unpack(dat)
    assert(not isopen,"dangling bench: "..name)
    tot\=0.01 --flr(tot*100)
    sys\=0.01

    printh(name.." "..tot, bench_filename, firstline)
    firstline=false
    if sys~=0 then
      printh(name..";sys "..sys, bench_filename)
    end
  end
  toast"benchmark saved"
end

function _bench_open(name)
  assert(#bench_scope>0) --todo rm -- always has top-level "p8" entry
  name=bench_scope[#bench_scope]..";"..name
  add(bench_scope,name)

  local entry=bench[name]
  if not entry then
    entry={0,0}
    bench[name]=entry
  end
  entry[3]=1 -- isopen
  entry[1]-=stat(1)
  entry[2]-=stat(2)
end
function _bench_close()
  local s1,s2=stat(1),stat(2)
  assert(#bench_scope>1)
  local name=deli(bench_scope)
  local entry=bench[name]
  assert(entry) --todo rm
  entry[1]+=s1
  entry[2]+=s2
  entry[3]=nil --isopen
end

-- call this in many places to see cpu usage at each location
-- the first call should pass an argument, to signal a reset
_cpu_flag=0
function cpu_flag(x)
 _cpu_flag+=1
 if x then
  _cpu_flag=0
  printh("---")
 end
 printh(_cpu_flag.." stat(1): "..stat(1))
end



-- profiler
--  BY PANCELOR
-- more info: https://www.lexaloffle.com/bbs/?tid=46117

--quickstart: (run in _init maybe)
-- local dat=profile("label",func) --simple
-- profile("label",func,{compare=dat,n=0x200,args={1,2,3}}) --all options
function profile(name,func, opts)
  local dat=profile_one(func,opts)
  profiler_report(name,dat,opts)
  return dat
end

function profile_one(func, opts)
  opts=opts or {}
  local compare=opts.compare or {lua=0,sys=0,tot=0}
  local n = opts.n or 0x400
  local args = opts.args or {}

  -- n must be larger than 256, or m will overflow
  assert(n>0x100)

  -- we want to type
  --   local m = 0x80_0000/n
  -- but 8MHz is too large a number to handle in pico-8,
  -- so we do (0x80_0000>>16)/(n>>16) instead
  -- (n is always an integer, so n>>16 won't lose any bits)
  local m = 0x80/(n>>16)

  assert(stat(8)==30) --target fps
  local function cycles(t0,t1,t2) return (t0+t2-2*t1)*m/30 end
  -- given three timestamps (pre-calibration, middle, post-measurement),
  --   calculate how many more CPU cycles func() took compared to nop()
  -- derivation:
  --   T := ((t2-t1)-(t1-t0))/n (frames)
  --     this is the extra time for each func call, compared to nop
  --     this is measured in #-of-frames (at 30fps) -- it will be a small fraction for most ops
  --   F := 1/30 (seconds/frame)
  --     this is just the framerate that the tests run at, not the framerate of your game
  --     can get this programmatically with stat(8) if you really wanted to
  --   M := 256*256*128 = 8MHz (cycles/second)
  --     (PICO-8 runs at 8MHz; source: https://www.lexaloffle.com/bbs/?tid=37695)
  --   cycles := T frames * F seconds/frame * M cycles/second
  -- optimization / working around pico-8's fixed point numbers:
  --   T2 := T*n = (t2-t1)-(t1-t0)
  --   M2 := M/n := m (e.g. when n is 0x1000, m is 0x800)
  --   cycles := T2*M2*F

  -- calibrate, then measure
  local nop=function() end -- this must be local, because func is local
  flip()
  local atot,asys=stat(1),stat(2)
  for i=1,n do nop(unpack(args)) end
  local btot,bsys=stat(1),stat(2)
  for i=1,n do func(unpack(args)) end
  local ctot,csys=stat(1),stat(2)

  -- report
  local lua=cycles(atot-asys,btot-bsys,ctot-csys)
  local sys=cycles(asys,bsys,csys)
  local tot=lua+sys
  return {
    lua=lua-compare.lua,
    sys=sys-compare.sys,
    tot=tot-compare.tot,
  }
end

function profiler_report(name,dat, opts)
  opts=opts or {}
  local srel=opts.compare and "+" or " "
  local s=name.." :"
    ..srel..leftpad(dat.lua,2)
    .." +"..leftpad(dat.sys,2)
    .." ="..srel..leftpad(dat.tot,2)
    .." (lua+sys)"
  printh(s)
end
