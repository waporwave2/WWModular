function _init()
	if not dev then
		toast"warning: loud! turn down volume"
	end

	cartdata("wwmodular-1")
	projid=dget(0)+1

	speaker=new_speaker()
	leftbar=new_leftbar()

	-- palette
	pal(split"129,5,134,15,12,1,7,8,4,9,11,6,13,131,2",1)
	palt(0,false)
	palt(14,true)
	if dev_palpersist then poke(0x5f2e,1) end

	-- mouse+kb
	poke(0x5f2d,0x1)

	-- font; see also font.lua
	poke(0x5f58,0x81)

	trace,retrace,trace_frame=min,min,min

	ini_patchmode()
end

function menuitems()
	menuitem(0x301,"export",export_patch)
	if upd==upd_samplemode then
		menuitem(0x302,"return",ini_patchmode)
	else
		menuitem(0x302,"manage samples",ini_samplemode)
	end
	if (dev) menutrace(0x303)
	menuitem(0x305,"---",function() return true end) --visual separation from p8 menu
end

function menutrace(index)
	menuitem(index,trace==_trace and "∧trace stop" or "∧trace start",function()
		if trace==_trace then
			trace_stop()
		else
			trace_start()
		end
		menutrace(index)
	end)
end

function _update60()
	trace"_update60"
	upd_mouse()

	upd_droppedfile()

	upd()

	-- fill audio buffer
	local len=min(94,1536-stat(108))
	oscbuf={}

	trace"for_sample"
	-- local sam={}
	for i=1,len do
		-- play
		trace"play"
		if playing then
			play()
		end

		-- generate samples
		retrace"step"
		for mod in all(modules) do
			if mod.step then mod:step() end
		end

		retrace"vis"
		-- visualize
		local speaker_inp=mem[speaker.inp]/0x.0002*0x.0002 --mid(mem[speaker.inp],-1,0x.ffff)
		if hqmode and #oscbuf<=46 and i&1==0 then
			add(oscbuf,speaker_inp)--TODO
		end
		-- sam[i]=(speaker_inp+1)*127.5
		poke(0x42ff+i,(speaker_inp+1)*127.5)
		trace""
	end
	retrace"preserial"
	-- poke(0x4300,unpack(sam))
	trace""

	trace"serial"
	serial(0x808,0x4300,len)
	trace""

	if dev and btnp(4,1) and not upd~=upd_trackmode then
		-- debugmod(modules[held])
		hqmode=not hqmode
		toast(qq("hq?",hqmode))
	end
	trace""
end
function _draw()
	trace"drw"
	drw()
	retrace"_draw extra"

	--rcmenu
	if rcmenu then
		--local rch=#rcmenu*4
		rectwh(rcpx-1,rcpyc-1,27,2+#rcmenu*5,13)
		for i,item in ipairs(rcmenu) do
			rectfillwh(rcpx,rcpyc+i*5-5,25,5,6-(i&1)*5)
			?item,rcpx+1,rcpyc+5*i-4,7
		end
	end

	--mouse
	spr(0,mx,my)
	cpuusage=stat(1)

	drw_droppedfile()

	do_toast()
	-- print("\#0\15"..stat(0),0,0,7) --mem usage
	trace""
	trace_frame()
end

function draw_toprightmenu()
	spr(rec and 8 or 7,96,0)
	spr(9+pgmode,104,0)
	spr(playing and 12 or 13,112,0)
	spr(upd==upd_trackmode and 15 or 14,120,0)
end
