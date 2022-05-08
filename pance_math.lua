--[[
# math.lua

various pure math stuff
]]

-- return x, shifted by delta units
--  towards target.
-- does not overshoot
-- examples:
--  approach(0,10) -> 1
--  approach(1,10) -> 2
--  approach(20,10) -> 19
--  approach(1,10,3) -> 4
--  approach(7,10,3) -> 10
--  approach(7,10,100) -> 10
--  approach(7,-5,100) -> -5
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

function ease_exp(t)
 return 2^(-10*t)
end

function ease_back(t)
 return 2.70158*t*t*t-1.70158*t*t
end

-- usage:
--  start_slope = 0
--  end_slope = 4
--  ease = curry(easeby,start_slope,end_slope)
-- https://twitter.com/FarbsMcFarbs/status/1456830625617432576
-- https://www.desmos.com/calculator/zr116z0zpj
function easeby(a,b,t)
 return (b+a-2)*x^3 + (-2*a-b+3)*x^2 + a*x
end

-- pythag theorem, but mostly safe from 16-bit overflow
function dist(dx,dy)
 local b=max(abs(dx),abs(dy))
 local a=min(abs(dx),abs(dy))/b
 return b*sqrt(a^2+1)
end

function sgn0(x)
 return x==0 and 0 or sgn(x)
end

function align(n,a)
 -- assert(n==n\1,"n must be an integer")
 -- assert(a&(a-1)==0,"a must be a power of 2")
 return n&~(a-1)
end
