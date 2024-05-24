-- lmb=0,rmb=1,mmb=2
function mbtn(b)
	return _btn_helper(_mbtn,b)
end
function mbtnp(b)
	return _btn_helper(_mbtnp,b)
end
function mbtnr(b)
	return _btn_helper(_mbtnr,b)
end

mx,my,_mbtn_last=stat(32),stat(33),0,0

function upd_mouse()
	_mbtn,mx,my=stat(34),stat(32),stat(33)
	_mbtnp,_mbtnr,_mbtn_last=_mbtn&~_mbtn_last,~_mbtn&_mbtn_last,_mbtn
end

function _btn_helper(bits, b)
	-- "not" is required
	return not b and bits or bits>>b&1>0
end
