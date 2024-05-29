--[[
# benchmark.lua

various tools for performance benchmarking

dependencies:
- toast
- various others (e.g. addall)
]]

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
	trace=min
	retrace=min
	trace_frame=min
	
	printh("p8 "..tostr(timing.p8,2), filename, true)
	for fullname,s1 in pairs(timing) do
		if fullname~="p8" then
			printh(fullname.." "..tostr(s1,2), filename)
		end
	end
	toast("trace saved: "..filename)
end





-- call this in many places to see cpu usage at each callsite
-- call once with no args at the start of the frame, to reset it
-- usage:
--   bench()
--   bench'bg' --after bg is drawn
--   bench'actors'
--   bench'particles'
-- each call itself costs roughly 0.001 (0.1%) at 60fps
_bench=0 --prev stat(1) value
function bench(name)
  if name then
    local now=stat(1)
    printh(sub(now,1,5).." | "..sub(now-_bench,1,5).." | "..name)
    _bench=now
  else
    printh'\ntotal | diff  | name\n--------------------'
    _bench=0
  end
end
