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
		for ix,val in inext,oscbuf do
			val=(val+1)%2.01 - 1
			local y=115-val*10.9
			if val<0 then y=ceil(y) end
			line(79+ix,y)
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
		local x,y=mod.x,mod.y

		local yh2=y+5*max(#iname,#oname)+4 --y+h-2
		if hqmode then
			-- w=35,h=h. rect directly for speed
			rect(x-1,y,x+33,yh2+1,2)
			rect(x,y-1,x+34,yh2,4)
		end
		rectfill(x,y,x+33,yh2,3)

		?mod.name,x+1,y+1,0
		for ix=1,#iname do --cant iter over iname_user - mixer gets messed up
			local yy=y+ix*5+1
			?iname_user[ix],x+5,yy,0
			local col=7
			if hqmode then
				rectfill(x+1,yy,x+3,yy+2,7)
				col=0
			end
			pset(x+2,yy+1,col)
		end
		for ix=1,#oname do
			local yy=y+ix*5+1
			?oname_user[ix],x+22,yy,0
			local col=6
			if hqmode then
				rectfill(x+18,yy,x+20,yy+2,6)
				col=0
			end
			pset(x+19,yy+1,col)
		end

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
