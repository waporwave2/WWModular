--util

function fillp_from_addr(addr)
	-- assert(#fills==17)
	fillp(fills[mid(1,17,mem[addr]*8+9.5)&-1])

	-- local r = cos(t()\.33/9)%.4 + 0.8 --random sparkle every 1/3 second
	-- fillp(fills[mid(1,17,mem[addr]*r*8+9.5)&-1])
end

function phzstep(phz,fr)
	-- phz+=(fr+1)*0.189841269841
	-- return ((phz+1)%2)-1 --wrap into -1,1
	return ((phz+fr*0.18984+1.18984)&0x1.ffff)-1 --wrap into -1,1
end

-- position of an in/out port on a module
function iop(mod,pix,is_input)
	return mod.x+(is_input and 2 or 19), mod.y+5*pix+2
end

function iocollide(x,y,...)
	local px,py=iop(...)
	return rect_collide(px-3,py-2,10,5, x,y)
end

-- get wire index the connects to a module
-- p: whether to search the start of the wire (p=1) or the end (p=3)
-- b: which input/output index to find. b=nil for any
function wirex(mod,p,b)
	-- assert(p==1 or p==3)
	for ix,wire in inext,wires do
		if wire[p]==mod and (not b or wire[4]==b) then
			return ix
		end
	end
end

function moduleclick()
	if con==nil then
		if held==nil then
			for mix,mod in inext,modules do
				conin=true
				for ipix=1,#mod.iname do
					-- ipix = "in port index"
					if iocollide(mx,my,mod,ipix,conin) then
						local wix=wirex(mod,3,ipix)
						if wix then
							concol=wires[wix][5]
							con=wires[wix][1]
							conid=wires[wix][2]
							conin=false
							delwire(wix)
						else
							con=mod
							conid=ipix
							conin=true
							concol=rnd(wirecols)
						end
					end
				end
				if con then
					break
				end
				conin=false
				for opix=1,#mod.oname do
					-- opix = "out port index"
					if iocollide(mx,my,mod,opix,conin) then
						con=mod
						conid=opix
						conin=false
						concol=rnd(wirecols)
					end
				end
				if con then
					break
				end


				if not mod.ungrabable and mod_collide(mod,mx,my) then
					held=mix
					anchorx=mod.x-mx
					anchory=mod.y-my
				end
			end
		else
			local mod = modules[held]
			mod.x=mx+anchorx
			mod.y=my+anchory
			
			-- recalculate wire draw curves for every attached wire
			for wire in all(wires) do
				local frommod,fromport,tomod,toport=unpack(wire)
				if frommod==mod or tomod==mod then
					local ipx,ipy = iop(tomod,toport,true)
					local opx,opy = iop(frommod,fromport,false)
					wire[6] = plotwire(ipx,ipy,opx,opy)
				end
			end
		end
	end
end

function modulerelease()
	held=nil
	if con then
		for mix,mod in inext,modules do
			if mix!=con then
				if not conin then
					-- connecting output -> input
					for ipix=1,#mod.iname do
						if iocollide(mx,my,mod,ipix,true) then
							delwire(wirex(mod,3,ipix))
							addwire{con,conid,mod,ipix,concol}
						end
					end
				else
					-- connecting input -> output
					for opix=1,#mod.oname do
						if iocollide(mx,my,mod,opix,false) then
							addwire{mod,opix,con,conid,concol}
						end
					end
				end
			end
		end
	end
	con=nil
end

function mod_collide(mod,xp,yp)
	return rect_collide(
		mod.x-1,mod.y-1,
		36,5*max(#mod.iname,#mod.oname)+7,
		xp,yp)
end

function inmodule(xp,yp)
	for mix,mod in inext,modules do
		if not mod.ungrabable and mod_collide(mod,xp,yp) then
			return mix
		end
	end
	return -1
end

function delmod()
	local mod=modules[selectedmod]
	if not mod.undeletable then
		repeat
			local wix=wirex(mod,3)
			delwire(wix)
		until not wix
		repeat
			local wix=wirex(mod,1)
			delwire(wix)
		until not wix
		deli(modules,selectedmod)
		del(modules_that_step,mod)
	end
end

function addwire(wire)
	-- set input address of module we're connecting-to
	local frommod,fromport,tomod,toport=unpack(wire) -- index 5: color. index 6: cached draw locations
	local fromname,toname=frommod.oname[fromport],tomod.iname[toport]
	tomod[toname] = frommod[fromname]

	-- cache wire draw locations
	local ipx,ipy = iop(tomod,toport,true)
	local opx,opy = iop(frommod,fromport,false)
	wire[6] = plotwire(ipx,ipy,opx,opy)

	add(wires,wire)
end

-- cache and return a flat list of 2d points, even in not hqmode
function plotwire(x0,y0,x1,y1)
	local x50,y50 = (x0+x1)/2,(y0+y1)/2+36
	local res = {x0,y0}
	-- could t=0,1,0.125, but we hardcode the two endpoints for speed
	for t=0.125,0.875,0.125 do
		add(res,lerp( lerp(x0,x50,t), lerp(x50,x1,t), t))
		add(res,lerp( lerp(y0,y50,t), lerp(y50,y1,t), t))
	end
	add(res,x1)
	add(res,y1)
	return res
end

function drawwire(points,col)
	if hqmode then
		line(col)
		for i=1,#points,2 do
			line(points[i],points[i+1])
		end
	else
		-- HACK: assert(#points==18)
		line(points[1],points[2],points[17],points[18],col)
	end
end

-- id may be nil
-- delete the wire and reset the input address
function delwire(id)
	local wire = wires[id]
	if wire then
		local tomod,toport = wire[3],wire[4]
		local toname=tomod.iname[toport]
		tomod[toname]=0 --set address to 0 (mem[0] is always 0)
		deli(wires,id)
	end
end
