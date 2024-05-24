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

	--mouse
	mx,my,mbtn=stat(32),stat(33),stat(34)
	mbtnp,_mbtn_last=mbtn&~_mbtn_last,mbtn
	lmb,lmbp,rmbp=mbtn&1>0,mbtnp&1>0,mbtnp&2>0

	upd_droppedfile()

	upd()

	fill_audio_buffer(min(94,1536-stat(108)))

	if dev and btnp(4,1) and not upd~=upd_trackmode then
		-- debugmod(modules[held])
		hqmode=not hqmode
		toast(qq("hq?",hqmode))
	end
	trace""
end
function _draw()
	trace"draw"
	drw()
	trace"_draw extra"

	--rcmenu
	if rcmenu then
		--local rch=#rcmenu*4
		rectwh(rcpx-1,rcpyc-1,27,2+#rcmenu*5,13)
		for i,item in inext,rcmenu do
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
	pq("cpu: "..cpuusage)
	trace""
	trace""
	trace_frame()
end

function draw_toprightmenu()
	spr(rec and 8 or 7,96,0)
	spr(9+pgmode,104,0)
	spr(playing and 12 or 13,112,0)
	spr(upd==upd_trackmode and 15 or 14,120,0)
end



function fill_audio_buffer(len)
	-- the hottest part of the program;
	-- the inner loop runs up to 94 times per _frame_ O.o'
	-- we're splurging tokens here to save cpu
	
	-- trace"fill_audio_buffer"

	oscbuf={}

	-- trace"_" --lets us retrace inside the loop
	-- assert(len<=94)
	local speaker_inp,speaker_spd=speaker.inp,speaker.spd
	if playing then
		local dpg_minus1 = pgmode==0 and 0
				or pgmode==2 and -2
				or -1
		local num_pages = #page
		-- two separate loops; saves 0.5% cpu at cost of 57 tokens
		for addr=0x4400,0x43ff+len do
			-- retrace"play"
			do --if playing
				-- advance the tracker and update leftbar's outputs
				local old_trkp=trkp
				trkp+=mid(1,(mem[speaker_spd]+1)/600) --implicit 0 param
				if trkp>=16 then
					pg+=dpg_minus1
					pg%=num_pages
					pg+=1
					trkp-=16
				end
				local flr_trkp=trkp&-1
				if old_trkp&-1!=flr_trkp or old_trkp==0 then -- TODO: old_trkp==0 takes a large amount of cpu, (0.005 maybe) can it be removed somehow?
					-- tracker_senddata (inlined)
					for ix=1,6 do
						local n=page[pg][ix][flr_trkp+1][1]
						if n>-2 then
							mem[leftbar[ix]]=n
							mem[leftbar[ix+6]]=1
						else
							mem[leftbar[ix+6]]=-1
						end
					end
				else
					-- write to gat1, gat2, gat3, etc
					-- this unroll saves roughly 0.01 cpu - huge
					if pgtrg[1] then mem[leftbar[7]]=-1 end
					if pgtrg[2] then mem[leftbar[8]]=-1 end
					if pgtrg[3] then mem[leftbar[9]]=-1 end
					if pgtrg[4] then mem[leftbar[10]]=-1 end
					if pgtrg[5] then mem[leftbar[11]]=-1 end
					if pgtrg[6] then mem[leftbar[12]]=-1 end
				end
			end

			-- generate samples
			-- retrace"step"
			for mod in all(modules_that_step) do
				mod:step() --as fast as mod.step()
			end

			-- retrace"output"
			local speaker_byte=mem[speaker_inp]/0x.0002*0x.0002 --mid(mem[speaker_inp],-1,0x.ffff)
			-- faster than one giant poke-unpack. barely faster than a complicated poke4 too
			poke(addr,speaker_byte*127.5+127.5)
			if hqmode and addr&1==0 then
				oscbuf[(addr>>1)&0xff]=speaker_byte
			end
		end
	else
		-- not playing
		for addr=0x4400,0x43ff+len do
			-- generate samples
			-- retrace"step"
			for mod in all(modules_that_step) do
				mod:step() --as fast as mod.step()
			end

			-- retrace"output"
			local speaker_byte=mem[speaker_inp]/0x.0002*0x.0002 --mid(mem[speaker_inp],-1,0x.ffff)
			-- faster than one giant poke-unpack. barely faster than a complicated poke4 too
			poke(addr,speaker_byte*127.5+127.5)
			if hqmode and addr&1==0 then
				oscbuf[(addr>>1)&0xff]=speaker_byte
			end
		end
	end

	-- trace""
	-- ok, we can relax now

	-- trace"serial"
	serial(0x808,0x4400,len) --pcm out. 0x4400 so that oscbuf can bitwise&0xff nicely
	-- trace"_"
end
