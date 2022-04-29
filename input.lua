--[[
# input.lua

various input stuff, like btnr() or mbtn()
]]

--todo: remove mouse support if not using it
-- (to avoid popup in web version)
poke(0x5f2d,1) --enable mouse
-- poke(0x5f5c,8,5) --keyrepeat: handled by btnq

--[[
btnp() should be
 equivalent to the builtin
 (assuming no keyrepeat and no player2)
 (can +8 at callsite if you want player2)
in practice, btnp() sometimes
 is different, (at startup)
 but it's probably fine
]]

-- TODO: btnp(6) (in keyboard.lua) does not work
--   btn() may not report it? its undocumented

function btnp(b) return _btn_helper(_btnp,b) end
function btnr(b) return _btn_helper(_btnr,b) end
function mbtn(b) return _btn_helper(_mbtn,b) end
function mbtnp(b) return _btn_helper(_mbtnp,b) end
function mbtnr(b) return _btn_helper(_mbtnr,b) end

-- mouse keycodes:
--  lmb=0,rmb=1,mmb=2

--[[
# implementation details
]]

-- save tokens maybe: parse_into(_ENV,...)
_btn_last,_btn,_btnp,_btnr,
_mbtn_last,_mbtn,_mbtnp,_mbtnr
=unpack(split"0,0,0,0,0,0,0,0")

mx,my,mwheel=stat(32),stat(33),0
--mpx,mpy

-- call this at the start
--  of _update()
function upd_btns()
 _btn,
 _mbtn,
 mpx,mpy,
 mx,my,mwheel
 =
 btn(),
 stat(34),
 mx,my,
 stat(32),stat(33),stat(36)

 _btnp,
 _btnr,
 _btn_last,
 _mbtnp,
 _mbtnr,
 _mbtn_last
 =
 _btn&~_btn_last,
 ~_btn&_btn_last,
 _btn,
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
