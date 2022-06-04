--[[
# math.lua

various pure math stuff
]]

-- return x, shifted by delta units
--  towards target.
-- does not overshoot
function approach(x,target,delta)
 delta=delta or 1
 return x<target and min(x+delta,target) or max(x-delta,target)
end

-- ⧗
function lerp(a,b,t) return a+(b-a)*t end
-- returns t such that x=lerp(a,b,t)
function ilerp(a,b,x) return (x-a)/(b-a) end

function clerp(a,b,t) return mid(a,b,a+(b-a)*t) end
function iclerp(a,b,x) return mid(1,(x-a)/(b-a)) end

function remap(x,a,b,u,v) return u+(v-u)*(x-a)/(b-a) end
function cremap(x,a,b,u,v) return mid(u,v,u+(v-u)*(x-a)/(b-a)) end

-- angle lerp
function aerp(a0,a1,t)
 return a0+t*wrap(a1-a0,-.5,.5)
end

-- like %, but with a shifted output range
-- returns something in [xmin,xmax)
function wrap(x,xmin,xmax)
 return (x-xmin)%(xmax-xmin)+xmin
end
-- assert(wrap(5,0,2)==1)
-- assert(wrap(5,-1,1)==-1)
-- assert(wrap(5,-2,1)==-1)
-- assert(wrap(5,2,4)==3)
-- assert(wrap(.2,2,4)==2.2)
-- assert(wrap(.2,3,5)==4.2)
-- -- assert(wrap(.2,-1,0)==-.8) -- fails b/c it's off by 0x.0001

function isxinxx(x,x0,x1)
  return min(x0,x1)<=x and x<=max(x0,x1)
end
function isxinxw(x,x0,w)
  assert(w>=0)
  return x0<=x and x<x0+w
end
