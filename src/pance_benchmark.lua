--[[
# benchmark.lua

various tools for performance benchmarking

dependencies:
- toast
- various others (e.g. addall)
]]

function noop() end

-- trace usage:
-- - set trace(), retrace(), and trace_frame() to no-op functions inside _init()
-- - call trace_start()/trace_stop() to start/stop tracemarking
-- - call trace"label" to start a tracemarking scope; trace"" to close the scope
-- - call retrace"label" to do `trace"" trace(label)` but more efficiently
-- - call trace_frame() once at the end of _draw()
-- - open the output file (pyroscope.p8l) in sublime; run the "line endings: unix" command
-- - upload the output file to https://flamegraph.com/
-- the "days" in the web viewer are scaled way way up from reality; ignore them
local trace_log,timing
function trace_start()
  -- trace_log is a list of events {name,tot}
  -- the info is not processed until trace_stop()
  trace=_trace
  retrace=_retrace
  trace_frame=_trace_frame

  trace_log,timing={},{}
  -- timing: fullname=>stat(1)-total mapping. does _not_ include time spent in sub-scopes
end
-- send any name to "open" a scope, send name=nil or name="" to close it
-- nesting scopes is expected
function _trace(name)
  -- printh("mem "..(stat(0)/2048))

  -- "add(trace_log_alt_version,{name,stat(1)})" but faster
  local len=#trace_log+1
  trace_log[len]=name
  trace_log[len+1]=stat(1)
end
function _retrace(name)
  -- call this in a loop to halve the cost of measurement itself
  -- (we only check stat(1) once instead of twice, and stat(1) costs ~36 cycles)

  -- "trace(""); trace(name)" but faster
  local len,s1=#trace_log+1,stat(1)
  trace_log[len]=""
  trace_log[len+1]=s1
  trace_log[len+2]=name
  trace_log[len+3]=s1
end
-- call this at the end of _draw (not _update)
function _trace_frame()
  -- consider rest of the frame to be idle time
  -- (don't need to #trace_log+1 etc b/c this only happens once a frame, and this saves 15 tokens)
  local s1=stat(1)
  local ceils1=ceil(s1)
  if s1<=1 then
    addall(trace_log,"idle",s1,"",1)
  else
    addall(trace_log,"degraded",s1,"",ceils1)
  end
  -- keep track of total s1-time spent tracing;
  -- +2 or more in degraded FPS, +1 normally
  timing.p8=(timing.p8 or 0)+ceils1

  --
  -- consolidate trace info from this frame
  --

  -- stack is a stack of ";"-joined scope names
  --   e.g. {"foo", "foo;bar", "foo;bar;baz"}
  -- (does not include the current scope)
  local stack = {}
  local fullname = "p8" -- current scope
  -- reconstruct timing info
  for i=1,#trace_log-1,2 do
    local name,s1=trace_log[i],trace_log[i+1]
    -- +=s1/-=s1 are maybe confusing; here's an example:
    --   innerscope is opened at s1=0.4 and closed at s1=0.5
    --   then, outerscope+= .4-.5 == -.1 (correctly excludes timing of inner scope)
    --   and   innerscope+= -.4+.5 == .1
    if name and name~="" then
      -- open scope
      -- pq("open",fullname)
      timing[fullname]=(timing[fullname] or 0)+s1 --outer scope
      add(stack,fullname)
      fullname..=";"..name
      timing[fullname]=(timing[fullname] or 0)-s1 --inner scope
    else
      -- close scope
      -- pq("close",fullname)
      timing[fullname]+=s1 --inner scope
      fullname=deli(stack)
      timing[fullname]-=s1 --outer scope
    end
  end
  assert(#stack==0,#stack)
  assert(fullname=="p8")
  trace_log={}
end

function trace_stop( filename)
  filename=filename or "pyroscope.p8l"

  -- disable future calls to trace()
  trace=noop
  retrace=noop
  trace_frame=noop
  
  printh("p8 "..tostr(timing.p8,2), filename, true)
  for fullname,s1 in pairs(timing) do
    if fullname~="p8" then
      printh(fullname.." "..tostr(s1,2), filename)
    end
  end
  toast"trace saved"
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
  --   calculate how many more CPU cycles func() took compared to noop()
  -- derivation:
  --   T := ((t2-t1)-(t1-t0))/n (frames)
  --     this is the extra time for each func call, compared to noop
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
  local noop=function() end -- this must be local, because func is local
  flip()
  local atot,asys=stat(1),stat(2)
  for i=1,n do noop(unpack(args)) end
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

function leftpad(s,n, ch)
 ch=ch or " "
 s=tostr(s)
 while #s<n do
  s=ch..s
 end
 return s
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
