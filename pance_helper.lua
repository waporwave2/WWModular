--[[
# helper.lua

various useful functions
]]

--[[
# misc
]]

-- needs to be defined first
function arr0(zero,arr)
 arr[0]=zero
 return arr
end

dirx=arr0(-1,split"1,0,0,1,1,-1,-1")
diry=arr0(0,split"0,-1,1,-1,1,1,-1")

function rect_collide(x0,y0,w0,h0,x2,y2, w2,h2)
 return x2<x0+w0
    and y2<y0+h0
    and x0<x2+(w2 or 1)
    and y0<y2+(h2 or 1)
end

function offscreen(x,y)
 return not rect_collide(%0x5f28,%0x5f2a,128,128,x,y)
end

-- -- given a screenpos, return a worldpos
-- function ppi(x,y)
--  return (x+%0x5f28)\8,(y+%0x5f2a)\8
-- end

function hasbit(bits,bb)
  return (bits>>bb)&1~=0
end
function getbit(bits,bb)
  return (bits>>bb)&1
end

function sum(arr)
 local res=0
 for v in all(arr) do
  res+=v
 end
 return res
end

-- function step(edge,x)
--   return tonum(x>=edge)
-- end

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
  s..=(type(k)=="table" and k.base and "<"..k.base.name..">") or tostr(k)
  if k=="base" then
   s..="=<"..tostr(v and v.name)..">"
  else
   s..="="..quote(v)
  end
  s..=sep or ","
 end
 return s.."}"
end

-- usage:
--  tap("rect_collide")
-- will show all args to/results from rect_collide
function tap(fname, obj,drop_self)
 local obj=obj or _ENV
 local original=obj[fname]
 assert(type(fname)=="string","use tap(\"foo\") not tap(foo)")
 assert(type(original)=="function",type(original))
 obj[fname]=function(self,...)
  pq("->",fname,drop_self and "<self>" or self,...)
  local ret=original(self,...)
  pq("<-",fname,ret)
  return ret
 end
end

--[[
# strings
]]

hex=arr0("0",split("123456789abcdef","",false))
-- assert(hex[3]=="3")
-- assert(hex[13]=="d")

-- recommended range:
--  space (start=32)
--  this gets ~95 bytes of space until past tilde (ord=126)
--  (these chars are all 1 byte
--  on twitter, and are just generally the
--  good ascii printable block)
-- for full ascii 0-255 range, see
--  extra special cases here:
--  https://www.lexaloffle.com/bbs/?tid=38692
function pack_bytes(arr, start,last)
 start=start or 0
 last=last or 255
 local out=""
 for i=1,#arr do
  local c=arr[i]+start
  assert(c<=last)
  out..=c=="\"" and "\\\""
     or c=="\\" and "\\\\"
     or chr(c)
 end
 return out
end

-- https://www.lexaloffle.com/bbs/?tid=38692
function escape_binary_str(s)
 local out=""
 for i=1,#s do
  local c=sub(s,i,i)
  local nc=ord(s,i+1)
  local v=c
  if(c=="\"") v="\\\""
  if(c=="\\") v="\\\\"
  if(ord(c)==0) v=(nc and nc>=48 and nc<=57) and "\\x00" or "\\0"
  if(ord(c)==10) v="\\n"
  if(ord(c)==13) v="\\r"
  out..=v
 end
 return out
end

function strwidth(str)
 return print(str,0,0x4000)
end

-- usage:
--  print(center("hello❎❎❎❎❎❎",64,64,8))
function center(str,x,...)
 return str,x-strwidth(str)\2,...
end

-- i is an in-between-chars pointer
-- this is not the same sort of
-- number sub() uses
function splice(str,i,n, new)
 return sub(str,1,i)..(new or "")..sub(str,i+n+1)
end
--assert(splice("hello",0,1,"b")=="bello")
--assert(splice("hello",1,1)=="hllo")
--assert(splice("hello",4,1,"b")=="hellb")
--assert(splice("hello",2,3,"at")=="heat")

-- substring starting at i of length n
function ssub(str,i, n)
 return sub(str,i,i+(n or 1)-1)
end

-- https://www.lua.org/manual/2.4/node22.html
-- like "indexof", except returns nil
function strfind(str,substr, i0, i1)
 i0=i0 or 1
 i1=i1 or #str-#substr+1
 for i=i0,i1 do
  if sub(str,i,i+#substr-1)==substr then
   return i
  end
 end
end

function startswith(str,substr)
  return sub(str,1,#substr)==substr
end
function endswith(str,substr)
  return sub(str,#str-#substr+1)==substr
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
end
function do_toast()
 if _toast.t>0 then _toast.t-=1 end
 local t=remap(_toast.t,
  _toast.t0,0,
  0,14)
 t=mid(0,1,7-abs(t-7)) --plateau
 local y=lerp(128,121,t)
 rectfillwh(0,y,128,7,_toast.bg)
 print("\015".._toast.msg,1,y+1,_toast.fg)
end
