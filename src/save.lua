function export_patch()
	dset(0,projid)
	if web_version then
		printh(build_export_string(),"@clip",true)
		toast"exported to clipboard"
	else
		printh(build_export_string(),"wwmodular_patch"..projid..".p8l",true,true)
		toast("exported to desktop: patch"..projid)
	end
end

function build_export_string()
	local str="wm03\nmodules\n" -- sync version w/ importer
	local modlookup={}
	for ii,mod in inext,modules do
		modlookup[mod]=ii
		str..=export_module(ii,mod).."\n"
	end

	str..="wires\n"
	for ii,wire in inext,wires do
		str..=export_wire(ii,wire,modlookup).."\n"
	end

	str..="pgtrg\n"
	str..=export_pgtrg().."\n"

	str..="pages\n"
	for ii,sheet in inext,page do
		str..=export_page(ii,sheet).."\n"
	end

	str..="samples\n"
	for ii,sample in inext,samples do
		str..=export_sample(ii,sample).."\n"
	end

	return str
end

do_handle_file=0
function upd_droppedfile()
	if do_handle_file==1 then
		if upd==upd_samplemode then
			local len=serial(0x800,0x8000,0x7ff0)
			local n=mid(1,8,1+my\16)
			samples[n]=chr(peek(0x8000,len))
			sample_cachedraw(n)

			toast("imported sample #"..n)
			while stat(120) do
				serial(0x800,0x8000,0x7ff0) --ignore extra
				toast("partially imported sample #"..n)
			end
		else
			serial(0x800,0x4300,4) --read 4 magic bytes
			if $0x4300==0x3330.6d77 then --wm03
				import_state,pg,trkp,selectedmod,   playing,held,con,rcmenu,rcfunc,leftbar,speaker=unpacksplit"1,1,0,-1"
				modules,wires,pgtrg,page,mem={},{},{},{},{[0]=0}
				samples=split"~,~,~,~,~,~,~,~"
				_sample_cachedraw={}

				local ln=""
				while stat(120) do
					-- move data from dropped file into 0x4300
					local len=serial(0x800,0x4300,0x1000)

					for i=0,len-1 do
						local bb=@(0x4300+i)
						local c=chr(bb)
						if c=="\n" then
							import_line(ln)
							ln=""
						elseif c~="\r" then
							ln..=c
						end
					end
				end
				import_line(ln) --leftovers
				if import_state>=0 then
					toast"patch imported"
				end
			elseif $0x4300&0x0.ffff==0x0.6d77 then
				toast("old version? "..chr(peek(0x4302,2)),240)
				while stat(120) do
					serial(0x800,0x8000,0x7ff0)
				end
			else
				toast("bad magic bytes: "..tostr($0x4300,1),240)
				while stat(120) do
					serial(0x800,0x8000,0x7ff0)
				end
			end
		end
	end
	if do_handle_file==0 and stat(120) then
		do_handle_file=4 --wait a few frames
		drop_mouse=upd==upd_samplemode and mx+my*128 --must move mouse to import a sample
	elseif mx+my*128!=drop_mouse then
		drop_mouse=nil
		do_handle_file=max(do_handle_file-1)
	end
end

function drw_droppedfile()
	if do_handle_file>0 and not drop_mouse then
		local w,h=60,12
		local x,y=64-w\2,64-h\2
		rectwh(x-1,y,w,h,2)
		rectwh(x,y-1,w,h,4)
		rectfillwh(x,y,w-1,h-1,3)
		?"loading...",x+10,y+4,0
	end
end

function import_line(ln)
	if(ln=="")return
	if import_state==1 then
		if ln=="modules" then
			import_state=2
		else
			import_state=-1
			toast("bad file header: "..ln)
		end
	elseif import_state==2 then
		if ln=="wires" then
			import_state=3
		elseif not import_module(ln) then
			toast("bad module: "..ln)
			import_state=-1
		end
	elseif import_state==3 then
		if ln=="pgtrg" then
			import_state=4
		elseif not import_wire(ln) then
			toast("bad wire: "..ln)
			import_state=-1
		end
	elseif import_state==4 then
		if ln=="pages" then
			import_state=5
		elseif not import_pgtrg(ln) then
			toast("bad pgtrg: "..ln)
			import_state=-1
		end
	elseif import_state==5 then
		if ln=="samples" then
			import_state=6
		elseif not import_page(ln) then
			toast("bad page: "..ln)
			import_state=-1
		end
	elseif import_state==6 then
		if ln=="" then
			import_state=7
		elseif not import_sample(ln) then
			toast("bad sample: "..ln)
			import_state=-1
		end
	end
end

function export_module(ii,mod)
	local str=unsplit(":",ii,mod.saveid,mod.x,mod.y)
	if mod.custom_export then
		str..=":"..mod:custom_export()
	end
	return str
end
function import_module(ln)
	local dat=split(ln,":")
	local ix,saveid,x,y=unpack(dat)
	local maker=all_module_makers[saveid]
	if maker then
		local mod=maker()
		modules[ix]=mod
		mod.x=x
		mod.y=y
		if mod.custom_import then
			mod:custom_import(unpack(dat,5))
		end
		return true
	end
end

function export_wire(ii,wire,modlookup)
	local imodindex = assert(modlookup[wire[1]])
	local omodindex = assert(modlookup[wire[3]])
	return unsplit(":",ii,imodindex,wire[2],omodindex,wire[4],wire[5])
end
function import_wire(ln)
	local wix,iix,sloti,oix,sloto,col=unpacksplit(ln,":")
	if col then --found all
		local modi,modo = modules[iix],modules[oix]
		if modi and modo and sloti<=#modi.oname and sloto<=#modo.iname then
			assert(wix==#wires+1)
			if col&-1~=col then
				-- fraction; migrate old colors
				col=rnd(wirecols)
			end
			addwire{modi,sloti,modo,sloto,col}
			return true
		end
	end
end

function export_pgtrg()
	return unsplit(":",unpack(pgtrg))
end
function import_pgtrg(ln)
	local list=split(ln,":")
	if list and #list==6 then
		for ii,val in inext,list do
			pgtrg[ii] = val=="true"
		end
		return true
	end
end

function export_page(ii,sheet)
	local ids={}
	for column in all(sheet) do
		for note in all(column) do
			assert(#note==3)
			add(ids,note[3])
		end
	end

	return unsplit(":",ii,unpack(ids))
end
function import_page(ln)
	local ids=split(ln,":")
	if #ids==97 then --6*16+1
		local pix=deli(ids,1) -- ids is now 96 values
		addpage(pix,ids)
		return true
	end
end

function export_sample(ii,sample)
	return unsplit(":",ii,ord(sample,1,#sample))
end
function import_sample(ln)
	local dat=split(ln,":")
	samples[dat[1]]=chr(unpack(dat,2))
	sample_cachedraw(dat[1])
	return true
end
