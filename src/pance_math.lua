-- # math.lua

-- returns x, shifted towards x1
--   by dx(=1) units without overshooting
function approach(x,x1, dx)
	dx=dx or 1
	return mid(x1,x-dx,x+dx)
end

function lerp(a,b,t) return a+(b-a)*t end
function ilerp(a,b,x) return (x-a)/(b-a) end
