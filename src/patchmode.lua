--patch mode

-- returns whether any input happened
-- note: this only deals with choosing an option
-- from an existing rcmenu; creating rcmenu
-- is handled separately
function rcmenu_input()
	if mbtnp(0) and rcmenu then
		if rect_collide(rcpx,rcpyc,25,#rcmenu*5,mx,my) then
			local sel=mid(ceil((my-rcpyc+1)/5),1,#modmenu)
			if rcmenu!=modmenu and sel>1 then
				modules[selectedmod]:propfunc(sel-1)
			else
				rcfunc[sel]()
			end
			if rcmenu==modmenu then
				modules[#modules].x=rcpx-10
				modules[#modules].y=rcpy-3
			end
			rcmenu=nil
			return true
		else
			rcmenu=nil
		end
	end
end

-- returns whether any input happened
function topmenu_input()
	if mbtnp(0) and mx>=96 and my<8 then
		if mx<104 then
			rec=not rec
			if rec then
				local str="recording"

				if cpuusage>.8 then
					str..="; switch to lq mode"
					hqmode=false
				end
				toast(str)
				extcmd'audio_rec'
			else
				hqmode=true
				toast"recording saved to desktop"
				extcmd'audio_end'
			end
		elseif mx<112 then
			pgmode+=1
			pgmode%=3
		elseif mx<120 then
			playing=not playing
			if not playing then
				pause()
			else
				if pgmode==0 then
					pg=1
				end
				trkp=0
				if #page==0 then
					addpage()
				end
			end
		else
			if upd==upd_trackmode then
				ini_patchmode()
			else --elseif upd==upd_patchmode then
				ini_trackmode()
			end
		end
		return true
	end
end

function ini_patchmode()
	upd,drw=upd_patchmode,drw_patchmode
	menuitems()
end

function upd_patchmode()
	eat_keyboard() --eat input while not in tracker mode

	mem[leftbar.btx]=btn(5) and 1 or -1
	mem[leftbar.btz]=btn(4) and 1 or -1

	-- LMB
	if rcmenu_input() then
		-- don't fall through if click used by rcmenu
	elseif topmenu_input() then
		-- don't fall through if click used by topmenu
	elseif module_custom_input() then
		-- don't fall through
	elseif mbtn(0) then
		moduleclick()
	else
		modulerelease()
	end

	-- RMB
	if mbtnp(1) then
		--if on module, rcmenu = id
		selectedmod=inmodule(mx,my)
		if selectedmod>0 then
			rcmenu={"delete"}
			rcfunc={delmod}
			if modules[selectedmod].prop then
				for pr in all(modules[selectedmod].prop) do
					add(rcmenu,pr)
				end
			end
		else
			rcmenu=modmenu
			rcfunc=modmenufunc
		end
		rcpx=mx
		rcpy=my
		rcpyc=min(my,127-#rcmenu*5) --stay onscreen
	end
end

retrace,trace=min,min
function drw_patchmode()
	trace"drw_patchmode"

	trace"setup"
	cls(1)
	if web_version then
		?"audio quality suffers on\nweb. for best experience,\nplease download on pc.",22,50,6
	end
	--osc
	rectfill(80,104,126,126,0)
	if hqmode then
		rect(79,103,127,127,6)

		line(11)
		for lind,lval in ipairs(oscbuf) do
			lval=(lval+1)%2.01 - 1
			local y=115-lval*10.9
			if lval<0 then y=ceil(y) end
			line(79+lind,y)
		end
	end
	local cpustr=tostr(cpuusage\.001/1000)
	?"\facpu:"..sub(cpustr.."00000",1,5),81,105

	retrace"modules"
	local port = hqmode and "\#0o",64,64

	--modules
	for mod in all(modules) do
		-- locals for speed
		local iname,oname=mod.iname,mod.oname
		local iname_user,oname_user=mod.iname_user or iname,mod.oname_user or oname
		local x,y,h=mod.x,mod.y,5*max(#iname,#oname)+6

		if hqmode then
			rectwh(x-1,y,35,h,2)
			rectwh(x,y-1,35,h,4)
		end
		rectfillwh(x,y,34,h-1,3)
		?mod.name,x+1,y+1,0
		---[[ --0.830 cpu, 7718 tok
		local yy=y+1
		for ix=1,#iname do
			yy+=5
			?iname_user[ix],x+5,yy,0
			local col=7
			if hqmode then
				rectfill(x+1,yy,x+3,yy+2,7)
				col=0
			end
			pset(x+2,yy+1,col)
		end
		local yy=y+1
		for ix=1,#oname do
			yy+=5
			?oname_user[ix],x+22,yy,0
			local col=6
			if hqmode then
				rectfill(x+18,yy,x+20,yy+2,6)
				col=0
			end
			pset(x+19,yy+1,col)
		end
		--]]
		--[[ --0.830 cpu, 7726 tok
		local yy=y+1
		for ix=1,#iname do
			yy+=5
			if hqmode then
				-- spr(2,x+1,yy,3/8,3/8)
				rectfill(x+1,yy,x+3,yy+2,7)
				pset(x+2,yy+1,0)
			else
				pset(x+2,yy+1,7)
			end
			?iname_user[ix],x+5,yy,0
		end
		local yy=y+1
		for ix=1,#oname do
			yy+=5
			if hqmode then
				-- spr(1,x+18,yy,3/8,3/8)
				rectfill(x+18,yy,x+20,yy+2,6)
				pset(x+19,yy+1,0)
			else
				pset(x+19,yy+1,6)
			end
			?oname_user[ix],x+22,yy,0
		end
		--]]
		--[[ 0.831 cpu, 7744 tok
		if hqmode then
			local yy=y+1
			for ix=1,#iname do
				yy+=5
				?iname_user[ix],x+5,yy,0
				spr(2,x+1,yy, .375,.375)
			end
			local yy=y+1
			for ix=1,#oname do
				yy+=5
				?oname_user[ix],x+22,yy,0
				spr(1,x+18,yy, .375,.375)
			end
		else
			local yy=y+1
			for ix=1,#iname do
				yy+=5
				?iname_user[ix],x+5,yy,0
				pset(x+2,yy+2,7)
			end
			local yy=y+1
			for ix=1,#oname do
				yy+=5
				?oname_user[ix],x+22,yy,0
				pset(x+19,yy+1,6)
			end
		end
		--]]

		if mod.custom_render then
			mod:custom_render()
		end
	end

	retrace"mouse"
	if con then
		local px,py=iop(con,conid,conin)
		fillp_from_addr(conin and 0 or nth_outaddr(con,conid))
		drawwire(plotwire(px,py,mx,my),concol)
	end

	retrace"wires"
	for wire in all(wires) do
		fillp_from_addr(nth_outaddr(wire[1],wire[2]))
		drawwire(wire[6],wire[5])
	end
	fillp()
	trace""

	draw_toprightmenu()
	trace""
end
