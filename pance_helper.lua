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

-- returns a number that goes from 0 to 1 in period seconds
--  (never quite hits 1, actually)
function cycle(period)
 return time()%period/period
end
-- returns v0 for dur0 seconds,
--   then returns v1 for dur1 seconds,
--   then repeats
function pulse(v0,dur0,v1,dur1)
 return time()%(dur0+dur1)<dur0 and v0 or v1
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
function pqx(v) pq(tohex(v),"(",v,")") end
function pqb(v,...) pq(tobin(v,...),"(",v,")") end

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

-- quotes an array
--  (its annoying sometimes that qq returns {1=foo,2=bar}
--  when you want {foo,bar} instead)
function qa(t)
 local s="{"
 for v in all(t) do
  s..=quote(v)..","
 end
 return s.."}"
end
function pqa(arr) printh(qa(arr)) end

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

function strwidth(str)
 return print(str,0,0x4000)
end

-- usage:
--  print(center("hello❎❎❎❎❎❎",64,64,8))
function center(str,x,...)
 return str,x-strwidth(str)\2,...
end

function tohex(x)
 return tostr(x,1)
end

function tobin(x, h,l)
 h=h or 8
 l=l or -8
 local s="0b"
 for i=h-1,l,-1 do
  if(i==-1)s..="."
  s..=(x>>i)&1
 end
 return s
end

function hexdump(src,len)
 local src1=src+len
 while src<src1 do
  local line=sub(tostr(src,1),3,6).." "
  for j=0,15 do
   if j%8==0 then line..=" " end
   line..=sub(tostr(@src,1),5,6).." "
   src+=1
  end
  printh(line)
 end
end

function leftpad(s,n, ch)
 ch=ch or " "
 s=tostr(s)
 while #s<n do
  s=ch..s
 end
 return s
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

function rectfillborder(x,y,w,h,b,cborder,cmain)
 if b<0 then
  b*=-1
  x-=b    y-=b
  w+=b*2  h+=b*2
 end
 rectfillwh(x,y,w,h,cborder)
 rectfillwh(x+b,y+b,w-b*2,h-b*2,cmain)
end

--[[
# functionalish stuff
]]

function f_id(x) return x end
function nop() end

function fmap(table,f)
 local res={}
 for i,v in pairs(table) do
  res[i]=f(v)
 end
 return res
end

-- arr could be a general table here
function filter(arr,f)
 local res={}
 for i,v in pairs(arr) do
  if (f(v)) add(res,v)
 end
 return res
end

function _func_or_elem_finder(f)
 return type(f)=="function"
  and f
  or function(x) return x==f end
end

function fall(table,f)
 f=_func_or_elem_finder(f)
 for v in all(table) do
  if (not f(v)) return
 end
 return true
end

function find(arr,f)
 f=_func_or_elem_finder(f)
 for i,v in ipairs(arr) do
  if (f(v)) return v,i
 end
-- return nil,nil
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

function back(arr,n)
 return arr[#arr-(n or 1)+1]
end

function arreq(a,b)
 if #a~=#b then return end
 for i,x in ipairs(a) do
  if x~=b[i] then return end
 end
 return true
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
function toast(msg, fg,bg,t)
 _toast.msg=msg
 _toast.fg=fg or 15
 _toast.bg=bg or 8
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
 rectfillwh(0,y,128,7,_toast.bg)
 print("\015".._toast.msg,1,y+1,_toast.fg)
end

function unpacksplit(...)
  return unpack(split(...))
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
