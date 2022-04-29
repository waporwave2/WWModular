pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
--waporware modular synthesis
--digital signal processing toy

dev=true
-- dev_palpersist=dev
dev_visualdebug=dev

printh"---"
#include helper.lua
#include benchmark.lua
#include input.lua
#include math.lua
#include visualdebug.lua

-->8
local modmenu={}
local modmenufunc={}
local modprop={}
local modpropfunc={}

--tracker
local trks={0,0}
local trkp=0
local page={}
local pg=1
local oct=1
local pgtrg={false,false,false,false,false,false}

--top menu
local rec=false
local pgmode=0
local playing=false
local tracker_mode=false

local oscbuf={}
local modules={}
local wires={}
local held=nil
local con=nil
local conin=true
local conid=0
local concol=3
local rcmenu=nil
local rcfunc=nil
local selectedmod=-1
local rcp={0,0}
local anchor={0,0}--grab offset

function _init()

	--add modules to menu
	modmenu={"saw","sin","square",
	"mixer","tri","clip","lfo",
	"adsr"}
	modmenufunc={saw,sine,square,
	mixer,tri,cut,lfo,adsr}

	output()
	leftbar()

	-- palette
	pal(split"129,5,134,15,12,1,7,8,9,10,11,6,13,14,15",1)
	palt(0,false)
	palt(14,true)
	if dev_palpersist then poke(0x5f2e,1) end

	-- mouse+kb
	poke(0x5f2d,0x1)
-- poke(0x5f5c,8,5) --keyrepeat

	-- font
	poke(0x5f58,0x81)
	poke(unpack(split"0x5600,4,8,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,63,63,63,63,63,63,63,0,0,0,63,63,63,0,0,0,0,0,63,51,63,0,0,0,0,0,51,12,51,0,0,0,0,0,51,0,51,0,0,0,0,0,51,51,51,0,0,0,0,48,60,63,60,48,0,0,0,3,15,63,15,3,0,0,62,6,6,6,6,0,0,0,0,0,48,48,48,48,62,0,99,54,28,62,8,62,8,0,0,0,0,24,0,0,0,0,0,0,0,0,0,12,24,0,0,0,2,0,0,0,0,0,0,0,10,10,0,0,0,0,0,4,10,4,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,1,0,0,0,0,0,54,54,0,0,0,0,0,0,54,127,54,54,127,54,0,8,62,11,62,104,62,8,0,0,51,24,12,6,51,0,0,14,27,27,110,59,59,110,0,12,12,0,0,0,0,0,0,24,12,6,6,6,12,24,0,12,24,48,48,48,24,12,0,0,54,28,127,28,54,0,0,2,7,2,0,0,0,0,0,0,2,1,0,0,0,0,0,0,7,0,0,0,0,0,0,0,0,2,0,0,0,0,0,32,48,24,12,6,3,1,0,7,5,7,0,0,0,0,0,2,2,2,0,0,0,0,0,3,6,7,0,0,0,0,0,7,6,7,0,0,0,0,0,5,7,4,0,0,0,0,0,6,2,3,0,0,0,0,0,1,7,7,0,0,0,0,0,7,4,2,0,0,0,0,0,2,7,7,0,0,0,0,0,7,7,4,0,0,0,0,0,2,0,2,0,0,0,0,0,0,0,12,0,0,12,6,0,4,2,4,0,0,0,0,0,0,0,30,0,30,0,0,0,1,2,1,0,0,0,0,0,3,0,2,0,0,0,0,0,0,30,51,59,59,3,30,0,2,7,5,0,0,0,0,0,3,7,3,0,0,0,0,0,7,1,7,0,0,0,0,0,3,5,3,0,0,0,0,0,7,3,7,0,0,0,0,0,7,3,1,0,0,0,0,0,1,5,7,0,0,0,0,0,5,7,5,0,0,0,0,0,7,2,7,0,0,0,0,0,4,5,6,0,0,0,0,0,5,3,5,0,0,0,0,0,1,1,7,0,0,0,0,0,7,7,5,0,0,0,0,0,3,5,5,0,0,0,0,0,7,5,7,0,0,0,0,0,7,7,1,0,0,0,0,0,2,5,6,0,0,0,0,0,3,7,5,0,0,0,0,0,6,2,3,0,0,0,0,0,7,2,2,0,0,0,0,0,5,5,7,0,0,0,0,0,5,5,2,0,0,0,0,0,5,7,7,0,0,0,0,0,5,2,5,0,0,0,0,0,5,2,2,0,0,0,0,0,3,2,6,0,0,0,0,0,62,6,6,6,6,6,62,0,1,3,6,12,24,48,32,0,62,48,48,48,48,48,62,0,12,30,18,0,0,0,0,0,0,0,0,0,0,0,30,0,12,24,0,0,0,0,0,0,2,7,5,0,0,0,0,0,3,7,3,0,0,0,0,0,7,1,7,0,0,0,0,0,3,5,3,0,0,0,0,0,7,3,7,0,0,0,0,0,7,3,1,0,0,0,0,0,1,5,7,0,0,0,0,0,5,7,5,0,0,0,0,0,7,2,7,0,0,0,0,0,4,5,6,0,0,0,0,0,5,3,5,0,0,0,0,0,1,1,7,0,0,0,0,0,7,7,5,0,0,0,0,0,3,5,5,0,0,0,0,0,7,5,7,0,0,0,0,0,7,7,1,0,0,0,0,0,2,5,6,0,0,0,0,0,3,7,5,0,0,0,0,0,6,2,3,0,0,0,0,0,7,2,2,0,0,0,0,0,5,5,7,0,0,0,0,0,5,5,2,0,0,0,0,0,5,7,7,0,0,0,0,0,5,2,5,0,0,0,0,0,5,2,2,0,0,0,0,0,3,2,6,0,0,0,0,0,56,12,12,7,12,12,56,0,8,8,8,0,8,8,8,0,14,24,24,112,24,24,14,0,0,0,110,59,0,0,0,0,0,0,0,0,0,0,0,0,7,7,7,0,0,0,0,0,85,42,85,42,85,42,85,0,65,99,127,93,93,119,62,0,62,99,99,119,62,65,62,0,60,36,103,0,0,0,0,0,4,12,124,62,31,24,16,0,28,38,95,95,127,62,28,0,34,119,127,127,62,28,8,0,42,28,54,119,54,28,42,0,28,28,62,93,28,20,20,0,8,28,62,127,62,42,58,0,62,103,99,103,62,65,62,0,62,127,93,93,127,99,62,0,24,120,8,8,8,15,7,0,62,99,107,99,62,65,62,0,8,20,42,93,42,20,8,0,12,18,97,0,0,0,0,0,62,115,99,115,62,65,62,0,8,28,127,28,54,34,0,0,127,34,20,8,20,34,127,0,62,119,99,99,62,65,62,0,0,10,4,0,80,32,0,0,76,42,25,0,0,0,0,0,62,107,119,107,62,65,62,0,127,0,127,0,127,0,127,0,85,85,85,85,85,85,85,0"))
end

function _update60()
	upd_btns()
	old_update60()
end
function _draw()
	old_draw()
	-- dev_outline_modules()
	-- dd(print,selectedmod,16,16,7)
	drw_debug()
end

function old_update60()
	--tracker and input
	if tracker_mode then
		tracker()
	else
		while stat(30) do
			stat(31)
		end
	end

	if not tracker_mode then
		if btn(❎) then
			modules[2].oname[13]="on"
			modules[2].o[13]=1
		else
			modules[2].oname[13]="off"
			modules[2].o[13]=-1
		end
		if btn(🅾️) then
			modules[2].oname[14]="on"
			modules[2].o[14]=1
		else
			modules[2].oname[14]="off"
			modules[2].o[14]=-1
		end
		if btn(➡️) then modules[2].o[15]+=.01 end
		if btn(⬅️) then modules[2].o[15]-=.01 end
		modules[2].o[15]=mid(-1,modules[2].o[15],1)
		modules[2].oname[15]=flr(modules[2].o[15]*10)

		if btn(⬆️) then modules[2].o[16]+=.003 end
		if btn(⬇️) then modules[2].o[16]-=.003 end
		modules[2].o[16]=mid(-1,modules[2].o[16],1)
		modules[2].oname[16]=flr(modules[2].o[16]*10)
	end

	-- fill audio buffer
	local len=min(94,1536-stat(108))
	--len=stat(109)-stat(108)
	oscbuf={}
	for i=0,len-1 do
		if playing then
			play()
		end
		generate()
		if #oscbuf <=46 and i%2==0 then
			add(oscbuf,modules[1].i[1])
		end
		poke(0x4300+i,(modules[1].i[1]+1)*127.5)
	end
	serial(0x808,0x4300,len)


	if mbtn(0) then
		-- top right menu buttons?
		-- else, right-click menu?
		-- else, module click?
		-- module release (complicated conditions)
		if mx>=96 and my<8 and mbtnp(0) then
			if mx<104 then
				rec=not rec
				if rec then
					extcmd('audio_rec')
				else
					extcmd('audio_end')
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
					for x=1,11,2 do
						local n=page[pg][(x+1)/2][1][1]
						if n>-2 then
							modules[2].o[x]=n
							modules[2].o[x+1]=1
						else
							modules[2].o[x+1]=-1
						end
					end
				end
			else
				tracker_mode=not tracker_mode
				if tracker_mode then
					if #page==0 then
						addpage()
					end
				end
			end
		else
			if rcmenu==nil then
				if not tracker_mode then
					moduleclick()
				else
					modulerelease()
				end
			else
				if mx>=rcp[1] and
							mx<=rcp[1]+24 and
							my>=rcp[2] and
							my<=rcp[2]+#rcmenu*5-1 then
					local sel=mid(ceil((my-rcp[2]+1)/5),1,#modmenu)
					if rcmenu!=modmenu and sel>1 then
						modules[selectedmod]:propfunc(sel-1)
					else
						rcfunc[sel]()
					end
					if rcmenu==modmenu then
						modules[#modules].x=mx-10
						modules[#modules].y=my-3
					end
					rcmenu=nil
				else
					rcmenu=nil
				end
			end
		end
	else
		modulerelease()
	end
	if mbtnp(1) then
		--if on module, rcmenu = id
		if not tracker_mode then
			selectedmod=inmodule(mx,my)
			if selectedmod>0 then
				rcmenu={"delete"}
				rcfunc={delmod}
				if modules[selectedmod].prop then
					for x=1,#modules[selectedmod].prop do
						add(rcmenu,modules[selectedmod].prop[x])
					end
				end
			else
				rcmenu=modmenu
				rcfunc=modmenufunc
			end
		else

		end
		rcp={mx,my}
	end
end

function generate()
	for mod in all(modules) do
		mod:step()
	end
	for wire in all(wires) do
		wire[3].i[wire[4]]=wire[1].o[wire[2]]
	end
end


-->8
--modules

function saw()
	add(modules,{
	name="saw ∧",
	phase=0,
	iname={"frq"},
	i={-0.159101767797},
	oname={"out"},
	o={0},
	step=function(self)
		self.phase=phzstep(self.phase,self.i[1])
		self.o[1]=self.phase
	end
	})
end

function tri()
	add(modules,{
	name="tri ∧",--name
	iname={"frq"},
	i={0},
	oname={"out"},
	o={0},
	phase=0,--code
	step=function(self)
		self.phase=phzstep(self.phase,self.i[1])
		self.o[1]=abs(self.phase)*2-1
	end
	})
end

function sine()
	add(modules,{
	name="sin …",
	phase=0,
	iname={"frq"},
	i={0},
	oname={"out"},
	o={0},
	step=function(self)
		self.phase=phzstep(self.phase,self.i[1])
		self.o[1]=sin(self.phase/2)
	end
	})
end

function adsr()
	add(modules,{
	name="adsr",
	state=0,
	iname={"atk","dec","sus","rel","gat"},
	i={0,0,0,0,0},
	oname={"out"},
	o={-1},
	gat=true,
	prop={"gattrg"},
	propfunc=function(self,i)
		self.gat=not self.gat
	end,
	step=function(self)
		if self.state==0 then
			self.o[1]-=(((self.i[4]+1)*8)^2)/1024
		end
		if self.state==1 then
			self.o[1]+=(((self.i[1]+1)*8)^2)/1024
		end
		if self.state==2 then
			self.o[1]-=(((self.i[2]+1)*8)^2)/1024
		end
		if self.i[5]>0 then
			if self.state==0 then self.state=1 end
		elseif self.state!=1 or self.gat then
			self.state=0
		end
		if self.o[1]>=1 and self.state==1 then
			self.state=2
		end
		if self.o[1]<=self.i[3] and self.state==2 then
			self.state=3
		end
		self.o[1]=mid(-1,self.o[1],1)
	end
	})
end

function lfo()
	add(modules,{
	name="lfo …",
	phase=0,
	iname={"frq"},
	i={0},
	oname={"out"},
	o={0},
	step=function(self)
		self.phase=phzstep(self.phase,(self.i[1]-255)/256)
		self.o[1]=sin(self.phase/2)
	end
	})
end

function square()
	add(modules,{
	name="sqr ░",
	phase=0,
	iname={"frq","len"},
	i={0,0},
	oname={"out"},
	o={0},
	step=function(self)
		self.phase=phzstep(self.phase,self.i[1])
		self.o[1]=sgn(self.phase+self.i[2])
	end
	})
end

function output()
	add(modules,{
	name="output",
	undeletable=true,
	x=97,
	y=80,
	iname={"inp","spd"},
	i={32,1},
	o={},
	step=function(self)

	end
	})
end

function cut()
	add(modules,{
	name="clip",
	iname={"inp"},
	i={32},
	oname={"out"},
	o={0},
	step=function(self)
		self.o[1]=mid(-1,self.i[1],1)
	end
	})
end

function mixer()
	add(modules,{
	name="mixer",
	iname={"in","cv","in","cv"},
	i={0,0,0,0},
	oname={"out"},
	o={0},
	prop={"addrow","delrow"},
	propfunc=function(self,i)
		if i==1 then
			if #self.i<8 then
				add(self.iname,"in")
				add(self.iname,"cv")
				add(self.i,0)
				add(self.i,0)
			end
		elseif #self.i>2 then
			for x=1,2 do
				local wi=wirex(self,3,#self.i)
				if wi>0then
					deli(wires,wi)
				end
				deli(self.i)
				deli(self.iname)
			end
		end
	end,
	step=function(self)
		local o=0
		for x=1,#self.i,2 do
			o+=self.i[x]*(self.i[x+1]+1)/2
		end
		self.o[1]=o
	end
	})
end

function leftbar()
	add(modules,{
	name="",
	ungrabable=true,
	undeletable=true,
	x=-15,
	y=-5,
	iname={},
	i={},
	oname={"t1","gat","t2","gat","t3","gat","t4","gat","t5","gat","t6","gat","off","off","0","0"},
	o={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	step=function(self)

	end
	})
end

-->8
--util

function phzstep(phz,fr)
	phz+=(fr+1)*0.189841269841
	phz=((phz+1)%2)-1
	return phz
end

function iop(x,y,f)
		local lft=0
		local dwn=6+8*(y-1)
		if f then
			lft=2
		else
			lft=17
		end

		return {x.x+lft,x.y+dwn}
end

function wirex(mod,p,b)
	for x=1,#wires do
		if wires[x][p]==mod and (b==-1or wires[x][4]==b) then
			return x
		end
	end
	return -1
end

function test(mod)
	mod.i[1]=modules[2].o[1]
end

function moduleclick()
	if con==nil then
		if held==nil then
			for x=1,#modules do
				conin=true
				for y=1,#modules[x].i do
					local p=iop(modules[x],y,conin)
					if (p[1]-mx)^2+(p[2]-my)^2<25 then
						local wi=wirex(modules[x],3,y)
						if wi>0 then
							concol=wires[wi][5]
							con=wires[wi][1]
							conid=wires[wi][2]
							conin=false
							deli(wires,wi)
						else
							con=modules[x]
							conid=y
							conin=true
							concol=rnd(4)+8
						end
					end
				end
				if con!=nil then
					break
				end
				conin=false
				for y=1,#modules[x].o do
					local p=iop(modules[x],y,conin)
					if (p[1]-mx)^2+(p[2]-my)^2<25 then
						con=modules[x]
						conid=y
						conin=false
						concol=rnd(4)+8
					end
				end
				if con!=nil then
					break
				end



				local h=#modules[x].o
				if #modules[x].i>h then
					h=#modules[x].i
				end
				if not modules[x].ungrabable and
				mx>modules[x].x and
				mx<modules[x].x+27 and
				my>modules[x].y and
				my<modules[x].y+8*h+4 then
					held=x
					anchor[1]=modules[x].x-mx
					anchor[2]=modules[x].y-my
				end
			end
		else
			modules[held].x=mx+anchor[1]
			modules[held].y=my+anchor[2]
		end
	end
end

function modulerelease()
	held=nil
	if con!=nil then
		for x=1,#modules do
			if x!=con then
				if not conin then
					for y=1,#modules[x].i do
						local p=iop(modules[x],y,true)
						if (p[1]-mx)^2+(p[2]-my)^2<25 then
							local wi=wirex(modules[x],3,y)
							if wi>0 then
								deli(wires,wi)
							end
							add(wires,{con,conid,modules[x],y,concol})


						end
					end
				else
					for y=1,#modules[x].o do
						local p=iop(modules[x],y,false)
						if (p[1]-mx)^2+(p[2]-my)^2<25 then
							add(wires,{modules[x],y,con,conid,concol})


						end
					end
				end
			end
		end
	end
	con=nil
end

function dev_outline_modules()
	if not dev then return end
	for ii,mod in ipairs(modules) do
		local h=max(#mod.o,#mod.i)
		rect(mod.x,mod.y,mod.x+27,mod.y+8*h+4,5)
	end
end

function inmodule(xp,yp)
	for ii,mod in ipairs(modules) do
		local h=max(#mod.o,#mod.i)
		if not mod.ungrabable and
		xp>mod.x and
		xp<mod.x+27 and
		yp>mod.y and
		yp<mod.y+8*h+4 then
			return ii
		end
	end
	return -1
end

function delmod()
	local mod=modules[selectedmod]
	if not mod.undeletable then
		for x=1,#mod.i do
			local wi=wirex(mod,3,-1)
			if wi>0then
				deli(wires,wi)
			end
		end
		for x=1,#mod.o do
			local wi=wirex(mod,1,-1)
			if wi>0then
				deli(wires,wi)
			end
		end
		del(modules,mod)
	end
end

-->8
--draw

function old_draw()
	if not tracker_mode then
		--module mode
		cls(1)
		--osc
		rectfill(80,105,126,126,0)
		rect(79,104,127,127,6)
		for x=1,#oscbuf do
			local rind=min(x+1,#oscbuf)
			local lval=oscbuf[x]
			local rval=oscbuf[rind]
			lval=((lval+1)%2.01)-1
			rval=((rval+1)%2.01)-1
			line(79+x,116-lval*10.9,min(80+x,125),116-rval*10.9,11)
		end
		?"cpu:"..flr(stat(1)*100)/100,81,106,10

		--modules
		for mod in all(modules) do
			local h=max(#mod.o,#mod.i)

			rectfill(mod.x-1,mod.y,
				mod.x+27,
				mod.y+8*h+5,
				2)
			rectfill(mod.x,mod.y-1,
				mod.x+28,
				mod.y+8*h+4,
				4)
			rectfill(mod.x,mod.y,
				mod.x+27,
				mod.y+8*h+4,
				3)
			?mod.name,mod.x+1,mod.y+1,0
			for x=0,#mod.i-1 do
				spr(2,mod.x+1,mod.y+5+8*x)
				?mod.iname[x+1],mod.x+1,mod.y+9+8*x,0
			end
			for x=0,#mod.o-1 do
				spr(1,mod.x+16,mod.y+5+8*x)
				?mod.oname[x+1],mod.x+16,mod.y+9+8*x,0
			end
		end

		if con!=nil then
			local p=iop(con,conid,conin)
			line(mx,my,p[1],p[2],concol)
		end

		for wire in all(wires) do
			local ip = iop(wire[3],wire[4],true)
			local op = iop(wire[1],wire[2],false)
			line(ip[1],ip[2],op[1],op[2],wire[5])
		end
	else
		--tracker_mode
		cls(3)

		--top right menu
		--rectfill(95,0,128,8,0)
		sspr(0,8,32,64,95,9)
		sspr(96,8,32,120,96,8)
		?"oc- oc+",98,12,0
		?"pg- pg+",98,20,0
		?"pg< pg>",98,28,0

		--info
		rectfill(2,1,93,32,6)
		rectfill(3,2,92,31,0)
		print("waporware modular\na dsp synth toy.\ndesigned and coded by:\nwaporwave"..pulse("",.5,"█",.5),4,3,11)
		print("octave:"..oct.." page:"..pg,4,28,11)

		?"t1  t2  t3  t4  t5  t6",6,34,0
		rect(1,38,98,119,2)


		for x=0,5 do
			?pgtrg[x+1]and"trg"or"gat",x*16+4,122,0
			--trg gat buttons
			line(17+x*16,120,17+x*16,125,4)
			line(2+x*16,121,2+x*16,126,2)
			line(2+x*16,126,16+x*16,126,2)
			line(3+x*16,120,16+x*16,120,4)
			for y=0,15 do
				rectfill(x*16+2,y*5+39,x*16+17,y*5+43,(trks[1]==x and trks[2]==y)and 13or((y+x)%2)*5+1)
				local ch=page[pg][x+1][y+1][2]
				?ch,x*16+3,y*5+40,0
			end
		end
		line(1,flr(trkp)*5+39,1,flr(trkp)*5+43,10)
	end
	--rcmenu
	if rcmenu!=nil then
		--local rch=#rcmenu*4
		rect(rcp[1]-1,rcp[2]-1,rcp[1]+25,rcp[2]+#rcmenu*5,13)
		for x=0,#rcmenu-1 do
			rectfill(rcp[1],rcp[2]+x*5,rcp[1]+24,rcp[2]+x*5+4,(x%2*5)+1)
			?rcmenu[x+1],rcp[1]+1,rcp[2]+1+5*x,7
		end
	end

	--top-right menu
	spr(7+(rec and 1 or 0),96,0)
	spr(9+pgmode,104,0)
	spr(13-(playing and 1 or 0),112,0)
	spr(14+(tracker_mode and 1 or 0),120,0)

	--mouse
	spr(0,mx,my)
end

-->8
--tracker
--probably figure out frequency
-- -1 to 1 to hz

--optimization!
--wires seem to cause issues
--try having wires attached to
--modules instead, then they
--send output directly, isntead
--of searching
local lkeys={z={-0.937505972289,1},
s={-0.933779264214,2},
x={-0.929842331581,3},
d={-0.925676063067,4},
c={-0.921261347348,5},
v={-0.916579073101,6},
g={-0.911610129001,7},
b={-0.90635451505,8},
h={-0.900793119924,9},
n={-0.894887720975,10},
j={-0.888638318204,11},
m={-0.882006688963,12},
q={-0.874992833254,13},
w={-0.859684663163,15},
e={-0.842503583373,17},
r={-0.833139034878,18},
t={-0.8127090301,20},
y={-0.789775441949,22},
u={-0.76403248925,24},
i={-0.750004777831,25},
o={-0.719388437649,27},
p={-0.68502627807,29}
}

local nkeys={nil,
{-0.867558528428,14},
{-0.851352126135,16},
nil,
{-0.823220258003,19},
{-0.801567128524,21},
{-0.777276636407,23},
nil,
{-0.73513616818,28},
{-0.702704252269,30}}

local keyname={"c","c+","d","d+","e","f","f+","g","g+","a","a+","b"}

function tracker()
	if btnp(➡️) then trks[1]+=1 end
	if btnp(⬅️) then trks[1]-=1 end
	if btnp(⬇️) then trks[2]+=1 end
	if btnp(⬆️) then trks[2]-=1 end
	trks[1]%=6
	trks[2]%=16

	--gate and other buttons
	if mbtnp(1) then
		if mx>1and mx<98and
			my>119and my<127 then
			local tk=(mx-2)\16+1
			tk=mid(1,tk,6)
			pgtrg[tk]=not pgtrg[tk]
		end

		if mx>95and mx<127and
			my>9and my<33 then
			local y=(my-10)\8
			if mx<=111 then
				if y==0 then
					oct-=1
				elseif y==1 then
					delpage(pg)
					pg-=1
					pg=(pg-1)%(#page)+1
				else
					pg-=1
					pg=(pg-1)%(#page)+1
				end
			else
				if y==0 then
					oct+=1
				elseif y==1 then
					addpage()
					pg+=1
				else
					pg+=1
					pg=(pg-1)%(#page)+1
				end
			end
			oct=mid(0,oct,4)
		end
	end

	--key2note
	while stat(30) do
		local n=stat(31)
		if n=="\b"then
			for x=trks[2],15 do
				page[pg][trks[1]+1][x]=page[pg][trks[1]+1][x+1]
			end
			page[pg][trks[1]+1][16]={-2,"--"}
			trks[2]-=1
			trks[2]%=16
		end
		if n=="\r" or n=="p" then
			poke(0x5f30,1) --prevent pause
			if n=="\r" then
				for x=16,trks[2]+2,-1 do
					page[pg][trks[1]+1][x]=page[pg][trks[1]+1][x-1]
				end
				page[pg][trks[1]+1][trks[2]+1]={-2,"--"}
				trks[2]+=1
				trks[2]%=16
			end
		end
		if n=="\t" then
			trks[1]+=1
			trks[1]%=6
		end
		k=lkeys[n] or nkeys[tonum(n)]
		if k then
			local f=(k[1]+1)*(2^oct)-1
			local nn=keyname[(k[2]-1)%12+1]..ceil(k[2]/12)+oct-1
			page[pg][trks[1]+1][trks[2]+1]={f,nn}
			trks[2]+=1
		end
	end
end

function play()
	local inc=(modules[1].i[2]+1)/600
	trkp+=inc
	if trkp>16 then
		if pgmode==0 then
			pg+=1
			pg=(pg-1)%(#page)+1
		elseif pgmode==2 then
			pg-=1
			pg=(pg-1)%(#page)+1
		end
	end
	trkp%=16
	if flr(trkp-inc*2)!=flr(trkp) then
		for x=1,6 do
			if pgtrg[x] then
				modules[2].o[x*2]=-1
			end
		end
	end
	if flr(trkp-inc)!=flr(trkp) then
		for x=1,11,2 do
			local n=page[pg][(x+1)/2][flr(trkp)+1][1]
			if n>-2 then
				modules[2].o[x]=n
				modules[2].o[x+1]=1
			else
				modules[2].o[x+1]=-1
			end
		end
	end

end

function pause()
	for x=2,12,2 do
		modules[2].o[x]=-1
	end
end

function addpage()
	local newp={}

	for r=1,6 do
		add(newp,{})
		for c=1,16 do
			add(newp[#newp],{-2,"--"})
		end
	end
	add(page,newp)
end

function delpage(ii)
	if #page>1 then
		deli(page,ii)
	end
end

__gfx__
77777eee666eeeee777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee344444443444444444444444444444444444444444444444444444444444444444444444
70007eee606eeeee707eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee233333342333333433333334333333343333333433333334333333343333333433333334
7007eeee666eeeee777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee233883342336633433336334316666343363333433636334366133343663333433666634
70707eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee238888342366663431666634363333343666613433636334366661343688333433633634
77e77eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee238888342366663436336334333336343363363433636334366661343338873436636634
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee233883342336633431333334366661343333313433131334366133343333773431131134
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee233333342333333433333334333333343333333433333334333333343333333433333334
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee222222232222222322222223222222232222222322222223222222232222222322222223
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee44444444444444ee44444444444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e2eeeeeeeeeeeee4e2eeeeeeeeeeeee4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e2eeeeeeeeeeeee4e2eeeeeeeeeeeee4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e2eeeeeeeeeeeee4e2eeeeeeeeeeeee4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e2eeeeeeeeeeeee4e2eeeeeeeeeeeee4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e2eeeeeeeeeeeee4e2eeeeeeeeeeeee4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e22222222222222ee22222222222222eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee44444444444444ee44444444444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e2eeeeeeeeeeeee4e2eeeeeeeeeeeee4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e2eeeeeeeeeeeee4e2eeeeeeeeeeeee4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e2eeeeeeeeeeeee4e2eeeeeeeeeeeee4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e2eeeeeeeeeeeee4e2eeeeeeeeeeeee4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e2eeeeeeeeeeeee4e2eeeeeeeeeeeee4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e22222222222222ee22222222222222eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee44444444444444ee44444444444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e2eeeeeeeeeeeee4e2eeeeeeeeeeeee4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e2eeeeeeeeeeeee4e2eeeeeeeeeeeee4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e2eeeeeeeeeeeee4e2eeeeeeeeeeeee4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e2eeeeeeeeeeeee4e2eeeeeeeeeeeee4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e2eeeeeeeeeeeee4e2eeeeeeeeeeeee4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e22222222222222ee22222222222222eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeec77777777777777777777777cee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedccccccccccccccccccccccc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedccdcccccccccccccccccdcc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcdddcccccccccccccccdddc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedccdcccccccccccccccccdcc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedccccccccccccccccccccccc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedccccccccccccccccccccccc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedc222222222222222222222c7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedc23333333332c2c2c23332c7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedc222222222222222222222c7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedc220000000000000000022c7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedc220011100000001110022c7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedc2201bbb1000001bbb1022c7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedc221b1b1b10101b1b1b122c7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedc221b1b1b11b11b1b1b122c7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedc221bb11b1b1b1bb11b122c7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedc220111b101010111b1022c7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedc220000100000000010022c7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedc220000000000000000022c7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedc222222222222222222222c7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedc22222222222222222222cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedccccccccccccccccccccccc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedccccccccccccccccccccccc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcc6c6c666c666c666c666cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcc6c6c6c6c6c6c6c6c6c6cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcc666c666c666c6c6c66ccc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcc666c6c6c6ccc666c6c6cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedccccccccccccccccccccccc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcccc6c6c666c666c666cccc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcccc6c6c6c6c6c6c66ccccc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcccc666c666c66cc6cccccc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcccc666c6c6c6c6c666cccc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedccccccccccccccccccccccc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedccccccccccccccccccccccc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedccccccccccccccccccccccc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedccc686cccc666cccc666ccc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcc68886cc6bbb6cc65556cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcc68886cc6bbbbcc65556cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcc68886cc6bbb6cc65556cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedccc666cccc666cccc656ccc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedccccccccccccccccccccccc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedccccccccccccccccccccccc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedccc777ccccccccccc777ccc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcc78887ccccccccc75557cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcc78887ccccccccc75557cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcc78887ccccccccc75557cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedccc778ccccccccccc7775cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedccccc8ccccccccccccccc5c7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedccc6c68ccc777cccc6c6c5c7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedccc6c68cc78887ccc6c6c5c7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedccc666c8c78887ccc666c5c7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedccc666cc888887ccc666c5c7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcccccccccc777cccccccc5c7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcccccccccccccccccccc5cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcccccccccc666ccccccc5cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcccccccccc6c6ccccc55ccc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcccccccccc6c6cccc555ccc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcccccccccc666ccc775cccc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedccccccccccccccc777ccccc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedccccccccccccccc77cccccc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedccccccccccccccccccccccc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedccc66666666666666666ccc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcc6666666666666666666cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcc6666666666666666666cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcc6666666666666666686cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcc6666666666666666886cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcc6666666666666668886cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcc6666666666666688866cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcc6666666666666888666cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcc6666666666668886666cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcc6666666666688866666cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcc66666666668886666b6cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcc6666666668886666bb6cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcc666666668886666bbb6cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcc66666668886666bbb66cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcc6666668886666bbb666cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcc666668886666bbb6666cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcc66668886666bbb66666cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcc6668886666bbb666656cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcc668886666bbb6666556cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcc68886666bbb66665556cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcc6886666bbb666655566cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcc6666666666666666666cc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedccc66666666666666666ccc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedccccccccccccccccccccccc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedccccccccccccccccccccccc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedccdcccccccccccccccccdcc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedcdddcccccccccccccccdddc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedccdcccccccccccccccccdcc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedccccccccccccccccccccccc7ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeecdddddddddddddddddddddddcee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888eeeeee888777777888eeeeee888eeeeee888eeeeee888888888888888888888888888888888888ff8ff8888228822888222822888888822888888228888
8888ee888ee88778877788ee888ee88ee888ee88ee8e8ee88888888888888888888888888888888888ff888ff888222222888222822888882282888888222888
888eee8e8ee8777787778eeeee8ee8eeeee8ee8eee8e8ee88888e88888888888888888888888888888ff888ff888282282888222888888228882888888288888
888eee8e8ee8777787778eee888ee8eeee88ee8eee888ee8888eee8888888888888888888888888888ff888ff888222222888888222888228882888822288888
888eee8e8ee8777787778eee8eeee8eeeee8ee8eeeee8ee88888e88888888888888888888888888888ff888ff888822228888228222888882282888222288888
888eee888ee8777888778eee888ee8eee888ee8eeeee8ee888888888888888888888888888888888888ff8ff8888828828888228222888888822888222888888
888eeeeeeee8777777778eeeeeeee8eeeeeeee8eeeeeeee888888888888888888888888888888888888888888888888888888888888888888888888888888888
1111111111111e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111ee11e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111eee1e1e1eee11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111bb11bbb1b1111711166166616111666111116661111116616661611166611111666177117171166166616111666111116661177117111111111
1111111111111b1b1b111b1117111611161116111611111111611111161116111611161111111161171117771611161116111611111111611117111711111111
1111111111111b1b1bb11b1117111666166116111661111111611111166616611611166111111161171117171666166116111661111111611117111711111111
1111111111111b1b1b111b1117111116161116111611111111611171111616111611161111111161171117771116161116111611111111611117111711111111
1111111111111bbb1bbb1bbb11711661166616661611117116661711166116661666161111711666177117171661166616661611117116661177117111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111bb11bbb1b1111711166166616111666111116661661166616661666111111661666161116661111166617711717116616661611166611111666
1111111111111b1b1b111b1117111611161116111611111111611616161616661611111116111611161116111111116117111777161116111611161111111161
1111111111111b1b1bb11b1117111666166116111661111111611616166616161661111116661661161116611111116117111717166616611611166111111161
1111111111111b1b1b111b1117111116161116111611111111611616161616161611117111161611161116111111116117111777111616111611161111111161
1111111111111bbb1bbb1bbb11711661166616661611117116661616161616161666171116611666166616111171166617711717166116661666161111711666
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111eee1ee11ee1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111e111e1e1e1e111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111ee11e1e1e1e111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111e111e1e1e1e111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111eee1e1e1eee111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111eee1ee11ee11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111e111e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111ee11e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111e111e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111eee1e1e1eee1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1ee11ee111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1ee11e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111711111111111111111111111111
1e111e1e1e1e11711111111111111111111111111111111111111111111111111111111111111111111111111111111111111771111111111111111111111111
1eee1e1e1eee17111111111111111111111111111111111111111111111111111111111111111111111111111111111111111777111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111777711111111111111111111111
116616661666166611111eee1e1e1ee111ee1eee1eee11ee1ee11171116616661611166611711111111111111111111111111771111111111111111111111111
161111611611161617771e111e1e1e1e1e1111e111e11e1e1e1e1711161116111611161111171111111111111111111111111117111111111111111111111111
166611611661166611111ee11e1e1e1e1e1111e111e11e1e1e1e1711166616611611166111171111111111111111111111111111111111111111111111111111
111611611611161117771e111e1e1e1e1e1111e111e11e1e1e1e1711111616111611161111171111111111111111111111111111111111111111111111111111
166111611666161111111e1111ee1e1e11ee11e11eee1ee11e1e1171166116661666161111711111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111e1111ee11ee1eee1e111111116611111ccc1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111e111e1e1e111e1e1e111111161617771c1c1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111e111e1e1e111eee1e111111161611111c1c1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111e111e1e1e111e1e1e111111161617771c1c1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111eee1ee111ee1e1e1eee1111166111111ccc1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111eee11ee1eee1111161611111cc11111171711661666161116661111166611111ccc11111ee111ee11111111111111111111111111111111111111111111
11111e111e1e1e1e11111616177711c1111117771611161116111611111111611111111c11111e1e1e1e11111111111111111111111111111111111111111111
11111ee11e1e1ee111111161111111c11111171716661661161116611111116111111ccc11111e1e1e1e11111111111111111111111111111111111111111111
11111e111e1e1e1e11111616177711c11171177711161611161116111111116111711c1111111e1e1e1e11111111111111111111111111111111111111111111
11111e111ee11e1e1111161611111ccc1711171716611666166616111171166617111ccc11111eee1ee111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111118888
11111111116611111111116616661611166611111666177116161177171711711166166616111666111116661771161611111cc1117711111cc1117111178888
111111111616117117771611161116111611111111611711161611171171171116111611161116111111116117111616117111c11117117111c1111711718888
111111111616177711111666166116111661111111611711116111171777171116661661161116611111116117111161177711c11117177711c1111711718888
111111111616117117771116161116111611111111611711161611171171171111161611161116111111116117111616117111c11117117111c1111711718888
11111111166111111111166116661666161111711666177116161177171711711661166616661611117116661771161611111ccc117711111ccc117117118888
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111eee1ee11ee11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111e111e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111ee11e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111e111e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111eee1e1e1eee1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111661666161116661111116617711cc111771111116611111111111111111111111111111111111111111111111111111111111111111111111111111111
1111161116111611161111111616171111c111171777161611111111111111111111111111111111111111111111111111111111111111111111111111111111
1111166616611611166111111616171111c111171111161611111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111616111611161111111616171111c111171777161611111111111111111111111111111111111111111111111111111111111111111111111111111111
111116611666166616111171166117711ccc11771111166111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1ee11ee111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1ee11e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1eee11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
17711171111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11711117111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11771117111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11711117111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
17711171111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1ee11ee1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e1e1e1e111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e1e1e1e111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e1e1e1e111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e1e1eee111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e1e1ee111ee1eee1eee11ee1ee11111161116661666166616661666166611711171111111111111111111111111111111111111111111111111111111111111
1e1e1e1e1e1111e111e11e1e1e1e1111161116111611116116161616161617111117111111111111111111111111111111111111111111111111111111111111
1e1e1e1e1e1111e111e11e1e1e1e1111161116611661116116611666166117111117111111111111111111111111111111111111111111111111111111111111
1e1e1e1e1e1111e111e11e1e1e1e1111161116111611116116161616161617111117111111111111111111111111111111111111111111111111111111111111
11ee1e1e11ee11e11eee1ee11e1e1111166616661611116116661616161611711171111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1bbb1bb11bb111711666116616611616161116661166111111771111111111111111111111111111111111111111111111111111111111111111111111111111
1b1b1b1b1b1b17111666161616161616161116111611111111711111111111111111111111111111111111111111111111111111111111111111111111111111
1bbb1b1b1b1b17111616161616161616161116611666111117711111111111111111111111111111111111111111111111111111111111111111111111111111
1b1b1b1b1b1b17111616161616161616161116111116117111711111111111111111111111111111111111111111111111111111111111111111111111111111
1b1b1bbb1bbb11711616166116661166166616661661171111771111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
166116661666166611111c1c1c1c1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
161616161666161117771c1c1c1c1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
16161666161616611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
16161616161616111777111111111171111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
16161616161616661111111111111711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
82888222822882228888822882228222888282288222822288888888888888888888888888888888888882828228822282228882822282288222822288866688
82888828828282888888882888828288882888288282888288888888888888888888888888888888888882828828828282888828828288288282888288888888
82888828828282288888882888828222882888288222888288888888888888888888888888888888888882228828822282228828822288288222822288822288
82888828828282888888882888828882882888288882888288888888888888888888888888888888888888828828828288828828828288288882828888888888
82228222828282228888822288828222828882228882888288888888888888888888888888888888888888828222822282228288822282228882822288822288
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

__sfx__
010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
