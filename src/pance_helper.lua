-- # misc

function rect_collide(x0,y0,w0,h0,x2,y2, w2,h2)
	return x2<x0+w0
		and y2<y0+h0
		and x0<x2+(w2 or 1)
		and y0<y2+(h2 or 1)
end

-- # print-debugging tools

-- quotes all args and prints to host console
-- usage:
--   pq("handles nils", many_vars, {tables=1, work=11, too=111})
function pq(...) printh(qq(...)) return ... end
function pqx(v) pq(tostr(v,1),"(",v,")") return v end
function qx(v) return tostr(v,1) end

-- quotes all arguments into a string
-- usage:
--   ?qq("p.x=",x,"p.y=",y)
function qq(...)
	local args=pack(...)
	local s=""
	for i=1,args.n do
		s..=quote(args[i]).." "
	end
	return s
end

-- quote a single thing
-- like tostr() but for tables
-- don't call this directly; call pq or qq instead
function quote(t, depth)
	depth=depth or 4 --avoid inf loop
	if type(t)~="table" or depth<=0 then return tostr(t) end

	local s="{"
	for k,v in pairs(t) do
		s..=tostr(k).."="..quote(v,depth-1)..","
	end
	return s.."}"
end

-- # strings

hex=split("123456789abcdef","",false)
hex[0]="0"
-- assert(hex[3]=="3")
-- assert(hex[13]=="d")

--[[
# overrides / pico-8 things
]]

function rectfillwh(x,y,w,h,...)
	rectfill(x,y,x+w-1,y+h-1,...)
end
function rectwh(x,y,w,h,...)
	rect(x,y,x+w-1,y+h-1,...)
end

-- # table/array utils

-- addall(arr,1,2,3)
-- note that nils will be skipped, b/c add ignores them!
function addall(arr,...)
	for e in all{...} do
		add(arr,e)
	end
end

function deepcopy(tab)
	local res={}
	for k,v in pairs(tab) do
		res[k]=type(v)=="table" and deepcopy(v) or v
	end
	return res
end

function parse_into(obj,str, mapper)
	for str2 in all(split(str)) do
		local parts=split(str2,"=")
		if #parts==2 then
			local k,v=unpack(parts)
			obj[k]=mapper and mapper(k,v) or v
		else
			add(obj,str2)
		end
	end
	return obj
end
function parse(...)
	return parse_into({},...)
end

local _toast_t,_toast_t0=0,180 --p8 uses 40ish
function toast(msg, t)
	local skip_intro=_toast_t>0
	_toast_msg,_toast_t="\015"..msg,t or 180
	_toast_t0=_toast_t
	if skip_intro then _toast_t-=7 end
	printh(msg)
end
function do_toast()
	_toast_t=max(_toast_t-1)
	-- smoothstep-minus-smoothstep but linear:
	--    iclerp(0,7,_toast_t0-_toast_t)
	--   -iclerp(7,0,_toast_t)
	local y=128.5-7*(
		mid(1,(_toast_t0-_toast_t)/7)
		-mid(1,1-_toast_t/7)
	)
	rectfill(0,y,128,128,4)
	print(_toast_msg,1,y+1,0)
end

-- pq + toast
function pqn(...)
  toast(qq(...)) --printh included
  return ...
end

function unsplit(sep,...)
	local res
	for elem in all{...} do
		res=(res and res..sep or "")..tostr(elem)
	end
	return res
end
