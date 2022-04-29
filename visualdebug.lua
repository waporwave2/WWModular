--[[
# visualdebug.lua

a system to easily draw one-off debug info
to the screen
]]

-- registers a callback to be run (once) after the next _draw()
-- usage:
--  dd(pset,16,16,8)
--  dd(print,qq(x,y))
--  dd(function()
--   pset(8,8,7)
--   ...
--  end)
function dd(f,...)
 local args={...}
 add(_visual_debug,function()
  f(unpack(args))
 end)
end

-- like dd, but resets the camera before calling
function dd0(f,...)
 local args={...}
 add(_visual_debug,function()
  local cx,cy=camera()
  f(unpack(args))
  camera(cx,cy)
 end)
end

--[[
# implementation details
]]

_visual_debug={}

-- call this at the end of _draw()
function drw_debug()
 if dev_visualdebug then
  local cx,cy=cursor()
  local col=color()
  for f in all(_visual_debug) do
   f()
  end
  cursor(cx,cy)
  color(col)
 end

 _visual_debug={}
end
