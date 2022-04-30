--[[
# input.lua

various input stuff, like btnr() or mbtn()
]]

function mbtn(b) return _btn_helper(_mbtn,b) end
function mbtnp(b) return _btn_helper(_mbtnp,b) end
function mbtnr(b) return _btn_helper(_mbtnr,b) end

-- mouse keycodes:
--  lmb=0,rmb=1,mmb=2

--[[
# implementation details
]]

mx,my,mwheel,_mbtn_last=stat(32),stat(33),0,0
--mpx,mpy
-- _mbtn,_mbtnp,_mbtnr

-- call this at the start
--  of _update()
function upd_btns()
 _mbtn,
 mpx,mpy,
 mx,my,mwheel
 =
 stat(34),
 mx,my,
 stat(32),stat(33),stat(36)

 _mbtnp,
 _mbtnr,
 _mbtn_last
 =
 _mbtn&~_mbtn_last,
 ~_mbtn&_mbtn_last,
 _mbtn
end

function _btn_helper(bits, b)
 -- "not" is required b/c the "else"
 --  return value is a boolean
 return not b
  and bits
  or bits>>b&1>0
end

-- if kbtn"a" then ... end
-- function kbtn(ch)
--   return stat(28,ord(ch)-93)
-- end
