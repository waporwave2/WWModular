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
function pq(...) printh(qq(...)) end
pp=pq
function pqx(v) pq(tohex(v),"(",v,")") end

-- sorta like sprintf (from c)
-- usage:
--  ?qf("p={x=%,y=%}",p.x,p.y)
function qf(...)
 local args=pack(...)
 local fstr=args[1]
 local argi=2
 local s=""
 for i=1,#fstr do
  local c=sub(fstr,i,i)
  if c=="%" then
   s..=quote(args[argi])
   argi+=1
  else
   s..=c
  end
 end
 return s
end
function pqf(...) printh(qf(...)) end

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
#  overrides / pico-8 things
]]

function _rectbounds(x,y,w,h,...)
 return x,y,x+w-1,y+h-1,...
end
function rectfillwh(...)
 rectfill(_rectbounds(...))
end
function rectwh(...)
 rect(_rectbounds(...))
end

function nop() end

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

function merge_into(obj,...)
 -- careful that both inputs
 --  are either shallow or
 --  single-use!
 -- e.g. def={x={0}} is
 --  a bad idea because
 --  merge(def,{}).x[1]=1 will
 --  modify def.x too!
 for t in all{...} do
  for k,v in pairs(t) do
   obj[k]=v
  end
 end
 return obj
end
function merge(...)
 return merge_into({},...)
end

clone=merge

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
_toast={t=0,t0=180,msg=""}
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
 local s,any=""
 for elem in all{...} do
  if any then s..=sep end
  any=true
  s..=tostr(elem)
 end
 return s
end
