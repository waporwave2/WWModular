--[[
# helper.lua

various useful functions
]]

--[[
# misc
]]

function rect_collide(x0,y0,w0,h0,x2,y2, w2,h2)
 return x2<x0+w0
    and y2<y0+h0
    and x0<x2+(w2 or 1)
    and y0<y2+(h2 or 1)
end

--[[
# print-debugging tools
]]

-- quotes and returns its arguments
-- usage:
--  ?qq("p.x=",x,"p.y=",y)
function qq(...)
 local args=pack(...)
 local s=""
 for i=1,args.n do
  s..=quote(args[i]).." "
 end
 return s
end
function pq(...) printh(qq(...)) return ... end
function pqx(v) pq(tohex(v),"(",v,")") end

-- quote a single argument
-- like tostr, but works on tables
function quote(t,sep)
 if type(t)~="table" then return tostr(t) end

 local s="{"
 for k,v in pairs(t) do
  s..=tostr(k).."="..quote(v)..(sep or ",")
 end
 return s.."}"
end

--[[
# strings
]]

hex=split("123456789abcdef","",false)
hex[0]="0"
-- assert(hex[3]=="3")
-- assert(hex[13]=="d")

function tohex(x)
 return tostr(x,1)
end

--[[
# overrides / pico-8 things
]]

function rectfillwh(x,y,w,h,...)
  rectfill(x,y,x+w-1,y+h-1,...)
end
function rectwh(x,y,w,h,...)
  rect(x,y,x+w-1,y+h-1,...)
end

--[[
# table/array utils
]]

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

-- call do_toast() during _draw()
local _toast={t=0,t0=180,msg=""}
function toast(msg, t)
 _toast.msg=msg
 t=t or 180
 _toast.t0=t
 _toast.t=t
 printh(msg)
end
function do_toast()
 if _toast.t>0 then _toast.t-=1 end
 local t=remap(_toast.t,
  _toast.t0,0,
  0,14)
 t=mid(1,7-abs(t-7)) --plateau
 local y=lerp(128,121,t)
 rectfillwh(0,y,128,7,4) --bkg
 print("\015".._toast.msg,1,y+1,0)
end

function unsplit(sep,...)
 local res=""
 for ix=1,select("#",...) do
  local elem=select(ix,...)
  res..=sep..tostr(elem)
 end
 return sub(res,2)
end
